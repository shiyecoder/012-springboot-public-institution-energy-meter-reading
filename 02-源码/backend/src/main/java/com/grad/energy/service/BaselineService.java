package com.grad.energy.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.grad.energy.common.BizException;
import com.grad.energy.common.PageResult;
import com.grad.energy.common.Status;
import com.grad.energy.common.UserContext;
import com.grad.energy.dto.Requests;
import com.grad.energy.entity.*;
import com.grad.energy.mapper.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.*;

/**
 * 创新点：能耗基线偏差识别。
 *
 * 6 个因子（权重可配置、合计 100%）：
 *   历史均值、标准波动、建筑面积、使用人数、季节系数、当前读数增长率。
 * 计算规则：
 *   1. 取该表计最近 7 期读数，前 6 期作为基线，最新一期为待评期；
 *   2. 每个因子折算 0-100 的子分，权重加权得总分；
 *   3. 缺失因子不参与计算，权重按剩余项归一化并在结果中标注「未满足条件」；
 *   4. 总分 ≥75 突增 / 50-74 偏高 / <50 正常；
 *   5. 每次计算保存输入快照、规则版本、明细，结果可追溯；
 *   6. 人工修正只写 adjustLevel/adjustReason，原始 totalScore 不被覆盖。
 */
@Service
@RequiredArgsConstructor
public class BaselineService {

    private final BaselineRuleMapper ruleMapper;
    private final BaselineScoreMapper scoreMapper;
    private final MeterReadingMapper readingMapper;
    private final MeterMapper meterMapper;
    private final BuildingMapper buildingMapper;
    private final ObjectMapper json;

    public static final List<String> FACTORS = List.of("histMean", "stdDev", "area", "person", "season", "growth");
    public static final Map<String, String> FACTOR_LABEL = new LinkedHashMap<>() {{
        put("histMean", "历史均值");
        put("stdDev", "标准波动");
        put("area", "建筑面积");
        put("person", "使用人数");
        put("season", "季节系数");
        put("growth", "当前读数增长率");
    }};

    public Map<String, Object> currentRule() {
        BaselineRule r = enabledRule();
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("rule", r);
        m.put("weights", parse(r == null ? null : r.getWeightsJson()));
        m.put("thresholds", parse(r == null ? null : r.getThresholdJson()));
        m.put("factors", FACTORS.stream().map(k -> Map.of("key", k, "label", FACTOR_LABEL.get(k))).toList());
        return m;
    }

    /** 保存规则：权重合计必须 100%，旧版本置为 DISABLED，新版本号自增 */
    @Transactional
    public Map<String, Object> saveRule(Requests.RuleSave req) {
        if (req.getWeights() == null || req.getWeights().isEmpty()) {
            throw new BizException("权重配置不能为空");
        }
        BigDecimal sum = BigDecimal.ZERO;
        for (String k : FACTORS) {
            BigDecimal w = req.getWeights().get(k);
            if (w == null) {
                throw new BizException("缺少因子权重：" + FACTOR_LABEL.get(k));
            }
            if (w.compareTo(BigDecimal.ZERO) < 0) {
                throw new BizException("权重不能为负数：" + FACTOR_LABEL.get(k));
            }
            sum = sum.add(w);
        }
        if (sum.compareTo(new BigDecimal("100")) != 0) {
            throw new BizException("权重合计必须等于 100%，当前为 " + sum + "%");
        }
        int maxVer = ruleMapper.selectList(Wrappers.<BaselineRule>lambdaQuery()).stream()
                .map(r -> {
                    try {
                        return Integer.parseInt(r.getVersion().replace("v", ""));
                    } catch (Exception e) {
                        return 0;
                    }
                }).max(Integer::compareTo).orElse(0);
        for (BaselineRule old : ruleMapper.selectList(Wrappers.<BaselineRule>lambdaQuery()
                .eq(BaselineRule::getStatus, "ENABLED"))) {
            old.setStatus("DISABLED");
            ruleMapper.updateById(old);
        }
        BaselineRule r = new BaselineRule();
        r.setRuleName(req.getRuleName() == null ? "能耗基线偏差识别" : req.getRuleName());
        r.setVersion("v" + (maxVer + 1));
        r.setWeightsJson(write(req.getWeights()));
        r.setThresholdJson(write(req.getThresholds() == null ? Map.of("high", 75, "mid", 50) : req.getThresholds()));
        r.setStatus("ENABLED");
        r.setEffectiveTime(LocalDateTime.now());
        r.setCreateBy(UserContext.realName());
        ruleMapper.insert(r);
        return Map.of("id", r.getId(), "version", r.getVersion());
    }

    /** 执行识别：返回完整明细，前端据此展示「推荐结果 / 主要因素 / 未满足 / 可改进」 */
    @Transactional
    public Map<String, Object> evaluate(Requests.EvaluateReq req) {
        Meter meter = resolveMeter(req);
        BigDecimal area = BigDecimal.ZERO;
        BigDecimal persons = BigDecimal.ZERO;
        Building b = buildingMapper.selectById(meter.getBuildingId());
        if (b != null) {
            area = b.getBuildArea() == null ? BigDecimal.ZERO : b.getBuildArea();
            persons = BigDecimal.valueOf(b.getPersonCount() == null ? 0 : b.getPersonCount());
        }
        String period = req.getPeriod() == null ? latestPeriod(meter.getId()) : req.getPeriod();
        List<MeterReading> his = readingMapper.selectList(Wrappers.<MeterReading>lambdaQuery()
                .eq(MeterReading::getMeterId, meter.getId())
                .le(MeterReading::getPeriod, period)
                .orderByDesc(MeterReading::getPeriod).last("limit 7"));
        if (his.isEmpty()) {
            throw new BizException("该表计没有可用抄表记录，无法计算");
        }
        Collections.reverse(his);
        BigDecimal curr = his.get(his.size() - 1).getUsageAmount();
        List<BigDecimal> base = new ArrayList<>();
        for (int i = 0; i < his.size() - 1 && base.size() < 6; i++) {
            base.add(his.get(i).getUsageAmount());
        }
        if (base.isEmpty()) {
            throw new BizException("基线期数不足，至少需要 2 期抄表记录");
        }
        BigDecimal mean = avg(base);
        BigDecimal std = std(base, mean);
        BigDecimal prev = his.size() >= 2 ? his.get(his.size() - 2).getUsageAmount() : mean;
        int month = Integer.parseInt(period.substring(5, 7));
        BigDecimal seasonFactor = season(month);

        Map<String, BigDecimal> weights = weightsOf(enabledRule());
        Map<String, BigDecimal> subs = new LinkedHashMap<>();
        Map<String, String> notes = new LinkedHashMap<>();
        List<String> unmet = new ArrayList<>();
        List<String> improves = new ArrayList<>();

        BigDecimal dev = rate(curr, mean);
        subs.put("histMean", clamp(new BigDecimal("50").add(dev.multiply(new BigDecimal("1.5")))));
        notes.put("histMean", "近 " + base.size() + " 期均值 " + mean + "，本期 " + curr + "，偏离 " + dev + "%");

        if (std.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal z = curr.subtract(mean).divide(std, 2, RoundingMode.HALF_UP);
            subs.put("stdDev", clamp(new BigDecimal("50").add(z.multiply(new BigDecimal("25")))));
            notes.put("stdDev", "Z 值 " + z + "（标准差 " + std + "）");
        } else {
            unmet.add("历史波动数据不足，标准波动因子未参与计算");
            notes.put("stdDev", "历史用量无波动，因子跳过");
        }

        if (area.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal perArea = curr.divide(area, 3, RoundingMode.HALF_UP);
            BigDecimal ratio = perArea.divide(new BigDecimal("1.42"), 2, RoundingMode.HALF_UP);
            subs.put("area", clamp(ratio.multiply(new BigDecimal("50"))));
            notes.put("area", "单位面积能耗 " + perArea + " kWh/㎡（同类型均值 1.42）");
        } else {
            unmet.add("缺少建筑面积，单位面积能耗未参与计算");
            notes.put("area", "建筑面积缺失");
            improves.add("补录建筑建筑面积后可启用单位面积口径");
        }

        if (persons.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal perCap = curr.divide(persons, 2, RoundingMode.HALF_UP);
            BigDecimal ratio = perCap.divide(new BigDecimal("11.5"), 2, RoundingMode.HALF_UP);
            subs.put("person", clamp(ratio.multiply(new BigDecimal("50"))));
            notes.put("person", "人均能耗 " + perCap + " kWh/人（同类型中位 11.5）");
        } else {
            unmet.add("缺少使用人数，人均能耗未参与计算");
            notes.put("person", "使用人数缺失");
        }

        subs.put("season", clamp(new BigDecimal("50").subtract(
                seasonFactor.subtract(BigDecimal.ONE).multiply(new BigDecimal("500")))));
        notes.put("season", "本期季节系数 " + seasonFactor + "，可解释部分增长");

        BigDecimal growth = rate(curr, prev);
        subs.put("growth", clamp(new BigDecimal("50").add(growth.multiply(new BigDecimal("1.2")))));
        notes.put("growth", "环比 " + growth + "%（上期 " + prev + "）");

        BigDecimal total = BigDecimal.ZERO;
        BigDecimal usedWeight = BigDecimal.ZERO;
        List<Map<String, Object>> items = new ArrayList<>();
        for (String k : FACTORS) {
            if (!subs.containsKey(k)) {
                continue;
            }
            BigDecimal w = weights.getOrDefault(k, BigDecimal.ZERO);
            BigDecimal sub = subs.get(k);
            usedWeight = usedWeight.add(w);
            total = total.add(w.multiply(sub).divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP));
            Map<String, Object> it = new LinkedHashMap<>();
            it.put("key", k);
            it.put("label", FACTOR_LABEL.get(k));
            it.put("weight", w);
            it.put("score", sub);
            it.put("note", notes.get(k));
            items.add(it);
        }
        // 缺失因子按剩余权重归一化，保证总分仍在 0-100
        if (usedWeight.compareTo(BigDecimal.ZERO) > 0 && usedWeight.compareTo(new BigDecimal("100")) < 0) {
            total = total.multiply(new BigDecimal("100")).divide(usedWeight, 2, RoundingMode.HALF_UP);
        }
        total = total.setScale(1, RoundingMode.HALF_UP);

        String level;
        String conclusion;
        if (growth.compareTo(new BigDecimal("-25")) < 0) {
            level = Status.LV_HIGH;
            conclusion = "本期用量较上期下降 " + growth.abs() + "%，判断为突降，需核查表计与计量回路";
        } else if (total.compareTo(new BigDecimal("75")) >= 0) {
            level = Status.LV_HIGH;
            conclusion = "本期单位面积能耗 " + (area.compareTo(BigDecimal.ZERO) > 0
                    ? curr.divide(area, 2, RoundingMode.HALF_UP) + " kWh/㎡" : "偏高")
                    + "，超出近 6 期基线波动范围，建议核查设备运行与计量回路";
        } else if (total.compareTo(new BigDecimal("50")) >= 0) {
            level = Status.LV_MID;
            conclusion = "本期能耗高于基线但仍在可解释范围内，建议关注后续两期走势";
        } else {
            level = Status.LV_LOW;
            conclusion = "本期能耗处于基线波动范围内，无需处置";
        }
        List<String> factors = items.stream()
                .sorted((a, b2) -> ((BigDecimal) b2.get("score")).compareTo((BigDecimal) a.get("score")))
                .limit(3)
                .map(i -> i.get("label") + " " + i.get("score") + " 分")
                .toList();
        if (total.compareTo(new BigDecimal("50")) >= 0) {
            improves.add("补充本期设备增减说明与配电回路核查记录");
            improves.add("核对分项计量覆盖率，确认是否存在串表");
        }

        BaselineScore s = new BaselineScore();
        s.setScoreNo("BL-" + period.replace("-", "") + "-" + String.format("%04d", meter.getId()));
        s.setBuildingId(meter.getBuildingId());
        s.setMeterId(meter.getId());
        s.setEnergyType(meter.getEnergyType());
        s.setPeriod(period);
        BaselineRule rule = enabledRule();
        s.setRuleId(rule == null ? null : rule.getId());
        s.setRuleVersion(rule == null ? "v1" : rule.getVersion());
        Map<String, Object> input = new LinkedHashMap<>();
        input.put("currUsage", curr);
        input.put("baseMean", mean);
        input.put("baseStd", std);
        input.put("prevUsage", prev);
        input.put("buildArea", area);
        input.put("personCount", persons);
        input.put("seasonFactor", seasonFactor);
        input.put("basePeriods", base.size());
        s.setInputJson(write(input));
        s.setItemJson(write(items));
        s.setTotalScore(total);
        s.setLevel(level);
        s.setConclusion(conclusion);
        s.setMainFactors(String.join("；", factors));
        s.setUnmetJson(write(unmet));
        s.setImproveJson(write(improves));
        s.setAdoptFlag(0);
        s.setCalcTime(LocalDateTime.now());
        scoreMapper.insert(s);

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("id", s.getId());
        res.put("scoreNo", s.getScoreNo());
        res.put("buildingName", b == null ? "—" : b.getBuildingName());
        res.put("meterCode", meter.getMeterCode());
        res.put("period", period);
        res.put("ruleVersion", s.getRuleVersion());
        res.put("totalScore", total);
        res.put("level", level);
        res.put("levelLabel", Status.levelLabel(level));
        res.put("conclusion", conclusion);
        res.put("items", items);
        res.put("mainFactors", factors);
        res.put("unmet", unmet);
        res.put("improve", improves);
        res.put("input", input);
        return res;
    }

    public PageResult<Map<String, Object>> page(Map<String, String> q) {
        long page = nz(q.get("page")) ? Long.parseLong(q.get("page")) : 1;
        long size = nz(q.get("size")) ? Long.parseLong(q.get("size")) : 10;
        QueryWrapper<BaselineScore> w = new QueryWrapper<>();
        w.eq("deleted", 0);
        if (nz(q.get("level"))) {
            w.eq("level", q.get("level"));
        }
        if (nz(q.get("buildingId"))) {
            w.eq("building_id", Long.parseLong(q.get("buildingId")));
        }
        w.orderByDesc("calc_time");
        Page<BaselineScore> p = scoreMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (BaselineScore s : p.getRecords()) {
            Map<String, Object> x = new LinkedHashMap<>();
            x.put("id", s.getId());
            x.put("scoreNo", s.getScoreNo());
            x.put("period", s.getPeriod());
            x.put("totalScore", s.getTotalScore());
            x.put("level", s.getLevel());
            x.put("levelLabel", Status.levelLabel(s.getLevel()));
            x.put("adjustLevel", s.getAdjustLevel());
            x.put("adjustReason", s.getAdjustReason());
            x.put("adoptFlag", s.getAdoptFlag());
            x.put("calcTime", s.getCalcTime());
            x.put("ruleVersion", s.getRuleVersion());
            x.put("mainFactors", s.getMainFactors());
            Building b = buildingMapper.selectById(s.getBuildingId());
            x.put("buildingName", b == null ? "—" : b.getBuildingName());
            Meter m = s.getMeterId() == null ? null : meterMapper.selectById(s.getMeterId());
            x.put("meterCode", m == null ? null : m.getMeterCode());
            rows.add(x);
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    /** 人工修正：必填原因，只记录调整结果，原始分数不动 */
    public void adjust(Long id, String level, String reason) {
        BaselineScore s = scoreMapper.selectById(id);
        if (s == null) {
            throw new BizException(404, "计算记录不存在");
        }
        if (reason == null || reason.trim().length() < 5) {
            throw new BizException("人工修正原因不少于 5 个字");
        }
        if (level == null || !List.of(Status.LV_HIGH, Status.LV_MID, Status.LV_LOW).contains(level)) {
            throw new BizException("修正等级不合法");
        }
        s.setAdjustLevel(level);
        s.setAdjustReason(reason);
        s.setAdjustBy(UserContext.realName());
        s.setAdjustTime(LocalDateTime.now());
        s.setAdoptFlag(0);
        scoreMapper.updateById(s);
    }

    /** 采纳率 / 调整率统计，用于验证创新模块有效性 */
    public Map<String, Object> stat() {
        List<BaselineScore> all = scoreMapper.selectList(Wrappers.<BaselineScore>lambdaQuery());
        long total = all.size();
        long adjusted = all.stream().filter(s -> s.getAdjustLevel() != null).count();
        long high = all.stream().filter(s -> Status.LV_HIGH.equals(s.getLevel())).count();
        long mid = all.stream().filter(s -> Status.LV_MID.equals(s.getLevel())).count();
        long low = all.stream().filter(s -> Status.LV_LOW.equals(s.getLevel())).count();
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("total", total);
        m.put("high", high);
        m.put("mid", mid);
        m.put("low", low);
        m.put("adjusted", adjusted);
        m.put("adoptRate", total == 0 ? 0 : Math.round((total - adjusted) * 1000.0 / total) / 10.0);
        m.put("adjustRate", total == 0 ? 0 : Math.round(adjusted * 1000.0 / total) / 10.0);
        return m;
    }

    private Meter resolveMeter(Requests.EvaluateReq req) {
        if (req.getMeterId() != null) {
            Meter m = meterMapper.selectById(req.getMeterId());
            if (m == null) {
                throw new BizException(404, "表计不存在");
            }
            return m;
        }
        if (req.getBuildingId() == null) {
            throw new BizException("请选择建筑或表计");
        }
        List<Meter> list = meterMapper.selectList(Wrappers.<Meter>lambdaQuery()
                .eq(Meter::getBuildingId, req.getBuildingId())
                .eq(req.getEnergyType() != null, Meter::getEnergyType, req.getEnergyType())
                .orderByAsc(Meter::getId));
        if (list.isEmpty()) {
            throw new BizException("该建筑下没有可用表计");
        }
        return list.get(0);
    }

    private BaselineRule enabledRule() {
        return ruleMapper.selectOne(Wrappers.<BaselineRule>lambdaQuery()
                .eq(BaselineRule::getStatus, "ENABLED").orderByDesc(BaselineRule::getId).last("limit 1"));
    }

    @SuppressWarnings("unchecked")
    private Map<String, BigDecimal> weightsOf(BaselineRule r) {
        Map<String, Object> raw = parse(r == null ? null : r.getWeightsJson());
        Map<String, BigDecimal> m = new LinkedHashMap<>();
        for (String k : FACTORS) {
            Object v = raw.get(k);
            m.put(k, v == null ? BigDecimal.ZERO : new BigDecimal(String.valueOf(v)));
        }
        return m;
    }

    private Map<String, Object> parse(String s) {
        if (s == null || s.isBlank()) {
            return new LinkedHashMap<>();
        }
        try {
            return json.readValue(s, Map.class);
        } catch (Exception e) {
            return new LinkedHashMap<>();
        }
    }

    private String write(Object o) {
        try {
            return json.writeValueAsString(o);
        } catch (Exception e) {
            return "{}";
        }
    }

    private BigDecimal avg(List<BigDecimal> list) {
        BigDecimal sum = BigDecimal.ZERO;
        for (BigDecimal b : list) {
            sum = sum.add(b);
        }
        return sum.divide(BigDecimal.valueOf(list.size()), 2, RoundingMode.HALF_UP);
    }

    private BigDecimal std(List<BigDecimal> list, BigDecimal mean) {
        if (list.size() < 2) {
            return BigDecimal.ZERO;
        }
        BigDecimal s = BigDecimal.ZERO;
        for (BigDecimal b : list) {
            BigDecimal d = b.subtract(mean);
            s = s.add(d.multiply(d));
        }
        double v = Math.sqrt(s.doubleValue() / (list.size() - 1));
        return BigDecimal.valueOf(v).setScale(2, RoundingMode.HALF_UP);
    }

    private BigDecimal rate(BigDecimal curr, BigDecimal base) {
        if (base == null || base.compareTo(BigDecimal.ZERO) == 0) {
            return BigDecimal.ZERO;
        }
        return curr.subtract(base).multiply(new BigDecimal("100"))
                .divide(base, 2, RoundingMode.HALF_UP);
    }

    /** 季节系数：1、2、7、8、12 月为用能高峰 */
    private BigDecimal season(int month) {
        return switch (month) {
            case 1, 12 -> new BigDecimal("1.08");
            case 2 -> new BigDecimal("1.05");
            case 7, 8 -> new BigDecimal("1.12");
            case 6, 9 -> new BigDecimal("1.04");
            default -> new BigDecimal("1.00");
        };
    }

    private String latestPeriod(Long meterId) {
        MeterReading r = readingMapper.selectOne(Wrappers.<MeterReading>lambdaQuery()
                .eq(MeterReading::getMeterId, meterId).orderByDesc(MeterReading::getPeriod).last("limit 1"));
        if (r == null) {
            throw new BizException("该表计暂无抄表记录");
        }
        return r.getPeriod();
    }

    private static BigDecimal clamp(BigDecimal v) {
        if (v.compareTo(BigDecimal.ZERO) < 0) {
            return BigDecimal.ZERO;
        }
        if (v.compareTo(new BigDecimal("100")) > 0) {
            return new BigDecimal("100");
        }
        return v.setScale(1, RoundingMode.HALF_UP);
    }

    private static boolean nz(String s) {
        return s != null && !s.isBlank();
    }
}
