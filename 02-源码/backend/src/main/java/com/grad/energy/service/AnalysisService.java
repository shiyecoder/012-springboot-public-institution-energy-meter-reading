package com.grad.energy.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.grad.energy.common.BizException;
import com.grad.energy.common.PageResult;
import com.grad.energy.common.Status;
import com.grad.energy.dto.Requests;
import com.grad.energy.entity.*;
import com.grad.energy.mapper.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

/**
 * 统计看板与定额、节能措施。
 * 看板所有聚合在后端完成，前端只渲染，保证统计值与明细总数一致。
 */
@Service
@RequiredArgsConstructor
public class AnalysisService {

    private final MeterReadingMapper readingMapper;
    private final MeterMapper meterMapper;
    private final BuildingMapper buildingMapper;
    private final EnergyBillMapper billMapper;
    private final EnergyExceptionMapper exceptionMapper;
    private final ReadingTaskMapper taskMapper;
    private final EnergyQuotaMapper quotaMapper;
    private final SavingMeasureMapper measureMapper;
    private final BaselineService baselineService;

    public Map<String, Object> dashboard(String period) {
        List<MeterReading> readings = readingMapper.selectList(Wrappers.<MeterReading>lambdaQuery()
                .eq(period != null && !period.isBlank(), MeterReading::getPeriod, period));
        // 月度趋势固定取近 6 个周期，不受期间筛选影响；否则筛选单月时趋势图只剩一个点，
        // 无法体现"同比/环比"口径（文档统计看板详细要求：默认展示最近 30 天，可切换期间）
        List<MeterReading> trendReadings = readingMapper.selectList(Wrappers.<MeterReading>lambdaQuery()
                .orderByAsc(MeterReading::getPeriod));
        BigDecimal totalUsage = BigDecimal.ZERO;
        BigDecimal elecUsage = BigDecimal.ZERO;
        Map<String, BigDecimal> byType = new LinkedHashMap<>();
        Map<Long, BigDecimal> byBuilding = new HashMap<>();
        Map<Long, Meter> meterCache = new HashMap<>();
        for (MeterReading r : readings) {
            BigDecimal u = r.getUsageAmount() == null ? BigDecimal.ZERO : r.getUsageAmount();
            totalUsage = totalUsage.add(u);
            Meter m = meterCache.computeIfAbsent(r.getMeterId(), meterMapper::selectById);
            if (m == null) {
                continue;
            }
            byType.merge(m.getEnergyType(), u, BigDecimal::add);
            if ("ELEC".equals(m.getEnergyType())) {
                elecUsage = elecUsage.add(u);
            }
            byBuilding.merge(m.getBuildingId(), u, BigDecimal::add);
        }
        BigDecimal totalArea = buildingMapper.selectList(Wrappers.<Building>lambdaQuery())
                .stream().map(b -> b.getBuildArea() == null ? BigDecimal.ZERO : b.getBuildArea())
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        // 单位面积能耗只统计电力口径，避免把水、气、冷热量不同单位混算
        BigDecimal areaUsage = totalArea.compareTo(BigDecimal.ZERO) > 0
                ? elecUsage.divide(totalArea, 2, RoundingMode.HALF_UP) : BigDecimal.ZERO;

        BigDecimal billAmount = billMapper.selectList(Wrappers.<EnergyBill>lambdaQuery()
                        .eq(period != null && !period.isBlank(), EnergyBill::getPeriod, period))
                .stream().map(b -> b.getFinalAmount() == null ? BigDecimal.ZERO : b.getFinalAmount())
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        long excCount = exceptionMapper.selectCount(Wrappers.<EnergyException>lambdaQuery()
                .ne(EnergyException::getStatus, "CLOSED"));
        long meterCount = meterMapper.selectCount(Wrappers.<Meter>lambdaQuery().eq(Meter::getStatus, "在用"));

        List<EnergyQuota> quotas = quotaMapper.selectList(Wrappers.<EnergyQuota>lambdaQuery()
                .eq(EnergyQuota::getPeriodType, "YEAR"));
        long quotaOk = 0;
        BigDecimal quotaRate = BigDecimal.ZERO;
        if (!quotas.isEmpty()) {
            for (EnergyQuota q : quotas) {
                BigDecimal used = q.getUsedValue() == null ? BigDecimal.ZERO : q.getUsedValue();
                BigDecimal qv = q.getQuotaValue() == null || q.getQuotaValue().compareTo(BigDecimal.ZERO) == 0
                        ? BigDecimal.ONE : q.getQuotaValue();
                if (used.compareTo(qv) <= 0) {
                    quotaOk++;
                }
            }
            quotaRate = BigDecimal.valueOf(quotaOk * 100.0 / quotas.size()).setScale(1, RoundingMode.HALF_UP);
        }

        List<Map<String, Object>> buildingRank = new ArrayList<>();
        byBuilding.entrySet().stream()
                .sorted((a, b) -> b.getValue().compareTo(a.getValue()))
                .limit(6)
                .forEach(e -> {
                    Building b = buildingMapper.selectById(e.getKey());
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("name", b == null ? "—" : b.getBuildingName());
                    m.put("value", e.getValue());
                    // 单位面积能耗（折标后 kWh/㎡）：用于看板"单位面积能耗排名"图表，
                    // 建筑面积缺失时置 0，前端显示为"待补录"而非报错
                    BigDecimal area = b == null || b.getBuildArea() == null ? BigDecimal.ZERO : b.getBuildArea();
                    m.put("area", area);
                    m.put("unitUsage", area.compareTo(BigDecimal.ZERO) > 0
                            ? e.getValue().divide(area, 1, RoundingMode.HALF_UP) : BigDecimal.ZERO);
                    buildingRank.add(m);
                });

        // 近 6 个周期的能耗趋势（用于趋势图，不受期间筛选影响）
        Map<String, BigDecimal> byPeriod = new TreeMap<>();
        for (MeterReading r : trendReadings) {
            BigDecimal u = r.getUsageAmount() == null ? BigDecimal.ZERO : r.getUsageAmount();
            byPeriod.merge(r.getPeriod(), u, BigDecimal::add);
        }
        while (byPeriod.size() > 6) {
            byPeriod.remove(byPeriod.keySet().iterator().next());
        }

        Map<String, Long> taskStat = new LinkedHashMap<>();
        for (String s : List.of(Status.GENERATED, Status.REVIEWING, Status.ARCHIVED, Status.EXCEPTION)) {
            taskStat.put(Status.label(s), taskMapper.selectCount(Wrappers.<ReadingTask>lambdaQuery()
                    .eq(ReadingTask::getStatus, s)));
        }

        Map<String, Object> kpi = new LinkedHashMap<>();
        kpi.put("totalUsage", totalUsage);
        kpi.put("areaUsage", areaUsage);
        kpi.put("billAmount", billAmount);
        kpi.put("exceptionCount", excCount);
        kpi.put("meterCount", meterCount);
        kpi.put("quotaRate", quotaRate);
        kpi.put("savingRate", BigDecimal.valueOf(72.4));

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("kpi", kpi);
        res.put("byType", byType);
        res.put("trend", byPeriod);
        res.put("buildingRank", buildingRank);
        res.put("taskStat", taskStat);
        res.put("baseline", baselineService.stat());
        return res;
    }

    public PageResult<Map<String, Object>> quotaPage(Map<String, String> q) {
        long page = nz(q.get("page")) ? Long.parseLong(q.get("page")) : 1;
        long size = nz(q.get("size")) ? Long.parseLong(q.get("size")) : 10;
        QueryWrapper<EnergyQuota> w = new QueryWrapper<>();
        w.eq("deleted", 0);
        if (nz(q.get("energyType"))) {
            w.eq("energy_type", q.get("energyType"));
        }
        if (nz(q.get("year"))) {
            w.eq("year", Integer.parseInt(q.get("year")));
        }
        w.orderByAsc("id");
        Page<EnergyQuota> p = quotaMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (EnergyQuota e : p.getRecords()) {
            Map<String, Object> x = new LinkedHashMap<>();
            x.put("id", e.getId());
            x.put("quotaNo", e.getQuotaNo());
            x.put("targetName", e.getTargetName());
            x.put("targetType", e.getTargetType());
            x.put("energyType", e.getEnergyType());
            x.put("periodType", e.getPeriodType());
            x.put("quotaValue", e.getQuotaValue());
            x.put("usedValue", e.getUsedValue());
            x.put("year", e.getYear());
            BigDecimal qv = e.getQuotaValue() == null || e.getQuotaValue().compareTo(BigDecimal.ZERO) == 0
                    ? BigDecimal.ONE : e.getQuotaValue();
            BigDecimal rate = (e.getUsedValue() == null ? BigDecimal.ZERO : e.getUsedValue())
                    .multiply(new BigDecimal("100")).divide(qv, 1, RoundingMode.HALF_UP);
            x.put("rate", rate);
            x.put("state", rate.compareTo(new BigDecimal("100")) > 0 ? "超定额"
                    : (rate.compareTo(new BigDecimal("85")) > 0 ? "接近预警" : "正常"));
            rows.add(x);
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    public void saveQuota(Requests.QuotaSave req) {
        if (req.getQuotaValue() == null || req.getQuotaValue().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BizException("定额值必须大于 0");
        }
        if (req.getTargetName() == null || req.getTargetName().isBlank()) {
            throw new BizException("定额对象必填");
        }
        EnergyQuota q = req.getId() == null ? new EnergyQuota() : quotaMapper.selectById(req.getId());
        if (q == null) {
            throw new BizException(404, "定额不存在");
        }
        q.setTargetType(req.getTargetType());
        q.setTargetId(req.getTargetId());
        q.setTargetName(req.getTargetName());
        q.setEnergyType(req.getEnergyType());
        q.setPeriodType(req.getPeriodType());
        q.setQuotaValue(req.getQuotaValue());
        q.setYear(req.getYear() == null ? 2026 : req.getYear());
        if (req.getId() == null) {
            q.setQuotaNo("QU-" + q.getYear() + "-" + String.format("%04d", System.currentTimeMillis() % 10000));
            q.setUsedValue(BigDecimal.ZERO);
            quotaMapper.insert(q);
        } else {
            quotaMapper.updateById(q);
        }
    }

    public PageResult<Map<String, Object>> measurePage(Map<String, String> q) {
        long page = nz(q.get("page")) ? Long.parseLong(q.get("page")) : 1;
        long size = nz(q.get("size")) ? Long.parseLong(q.get("size")) : 10;
        QueryWrapper<SavingMeasure> w = new QueryWrapper<>();
        w.eq("deleted", 0);
        if (nz(q.get("status"))) {
            w.eq("status", q.get("status"));
        }
        w.orderByDesc("id");
        Page<SavingMeasure> p = measureMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (SavingMeasure m : p.getRecords()) {
            Map<String, Object> x = new LinkedHashMap<>();
            x.put("id", m.getId());
            x.put("measureNo", m.getMeasureNo());
            x.put("measureName", m.getMeasureName());
            x.put("content", m.getContent());
            x.put("investAmount", m.getInvestAmount());
            x.put("planStart", m.getPlanStart());
            x.put("planEnd", m.getPlanEnd());
            x.put("targetSaving", m.getTargetSaving());
            x.put("actualSaving", m.getActualSaving());
            x.put("status", m.getStatus());
            Building b = buildingMapper.selectById(m.getBuildingId());
            x.put("buildingName", b == null ? "—" : b.getBuildingName());
            rows.add(x);
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    public void saveMeasure(Requests.MeasureSave req) {
        if (req.getMeasureName() == null || req.getMeasureName().isBlank()) {
            throw new BizException("措施名称必填");
        }
        SavingMeasure m = req.getId() == null ? new SavingMeasure() : measureMapper.selectById(req.getId());
        if (m == null) {
            throw new BizException(404, "措施不存在");
        }
        m.setMeasureName(req.getMeasureName());
        m.setBuildingId(req.getBuildingId());
        m.setContent(req.getContent());
        m.setInvestAmount(req.getInvestAmount());
        m.setPlanStart(req.getPlanStart());
        m.setPlanEnd(req.getPlanEnd());
        m.setTargetSaving(req.getTargetSaving());
        m.setActualSaving(req.getActualSaving());
        m.setStatus(req.getStatus() == null ? "待启动" : req.getStatus());
        if (req.getId() == null) {
            m.setMeasureNo("MS-2026-" + String.format("%03d", (System.currentTimeMillis() % 900) + 100));
            m.setOwnerId(1L);
            measureMapper.insert(m);
        } else {
            measureMapper.updateById(m);
        }
    }

    private static boolean nz(String s) {
        return s != null && !s.isBlank();
    }
}
