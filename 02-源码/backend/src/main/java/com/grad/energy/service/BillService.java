package com.grad.energy.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.grad.energy.common.BizException;
import com.grad.energy.common.PageResult;
import com.grad.energy.entity.*;
import com.grad.energy.mapper.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

/**
 * 费用核算：按能源类型与生效中的计费规则生成月度账单；
 * 账单生成后锁定对应抄表记录，后续调整统一走审批并留痕。
 */
@Service
@RequiredArgsConstructor
public class BillService {

    private final EnergyBillMapper billMapper;
    private final MeterReadingMapper readingMapper;
    private final MeterMapper meterMapper;
    private final BuildingMapper buildingMapper;
    private final TariffRuleMapper tariffMapper;

    public List<TariffRule> tariffs() {
        return tariffMapper.selectList(Wrappers.<TariffRule>lambdaQuery()
                .orderByDesc(TariffRule::getEffectiveDate));
    }

    public PageResult<Map<String, Object>> page(Map<String, String> q) {
        long page = num(q.get("page"), 1);
        long size = num(q.get("size"), 10);
        QueryWrapper<EnergyBill> w = new QueryWrapper<>();
        w.eq("deleted", 0);
        if (nz(q.get("period"))) {
            w.eq("period", q.get("period"));
        }
        if (nz(q.get("energyType"))) {
            w.eq("energy_type", q.get("energyType"));
        }
        if (nz(q.get("status"))) {
            w.eq("status", q.get("status"));
        }
        if (nz(q.get("buildingId"))) {
            w.eq("building_id", Long.parseLong(q.get("buildingId")));
        }
        w.orderByDesc("period").orderByDesc("id");
        Page<EnergyBill> p = billMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (EnergyBill b : p.getRecords()) {
            Map<String, Object> x = new LinkedHashMap<>();
            x.put("id", b.getId());
            x.put("billNo", b.getBillNo());
            x.put("energyType", b.getEnergyType());
            x.put("period", b.getPeriod());
            x.put("usageAmount", b.getUsageAmount());
            x.put("unitPrice", b.getUnitPrice());
            x.put("amount", b.getAmount());
            x.put("adjustAmount", b.getAdjustAmount());
            x.put("finalAmount", b.getFinalAmount());
            x.put("status", b.getStatus());
            x.put("lockFlag", b.getLockFlag());
            x.put("tariffVersion", b.getTariffVersion());
            Building bl = buildingMapper.selectById(b.getBuildingId());
            x.put("buildingName", bl == null ? "—" : bl.getBuildingName());
            Meter m = b.getMeterId() == null ? null : meterMapper.selectById(b.getMeterId());
            x.put("meterCode", m == null ? null : m.getMeterCode());
            rows.add(x);
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    /** 生成月度账单：只取已确认且未锁定的抄表记录，避免重复计费 */
    @Transactional
    public Map<String, Object> generate(String period) {
        if (period == null || !period.matches("\\d{4}-\\d{2}")) {
            throw new BizException("周期格式应为 yyyy-MM");
        }
        List<MeterReading> list = readingMapper.selectList(Wrappers.<MeterReading>lambdaQuery()
                .eq(MeterReading::getPeriod, period)
                .eq(MeterReading::getReviewStatus, "PASS")
                .eq(MeterReading::getLocked, 0));
        int created = 0;
        BigDecimal total = BigDecimal.ZERO;
        for (MeterReading r : list) {
            Meter m = meterMapper.selectById(r.getMeterId());
            if (m == null) {
                continue;
            }
            TariffRule rule = tariffMapper.selectOne(Wrappers.<TariffRule>lambdaQuery()
                    .eq(TariffRule::getEnergyType, m.getEnergyType())
                    .eq(TariffRule::getStatus, "ENABLED")
                    .orderByDesc(TariffRule::getEffectiveDate).last("limit 1"));
            if (rule == null) {
                continue;
            }
            BigDecimal price = rule.getPrice();
            BigDecimal amount = r.getUsageAmount().multiply(price).setScale(2, RoundingMode.HALF_UP);
            EnergyBill b = new EnergyBill();
            b.setBillNo("BILL-" + period.replace("-", "") + "-" + String.format("%04d", r.getId() % 10000));
            b.setBuildingId(m.getBuildingId());
            b.setMeterId(m.getId());
            b.setEnergyType(m.getEnergyType());
            b.setPeriod(period);
            b.setUsageAmount(r.getUsageAmount());
            b.setUnitPrice(price);
            b.setAmount(amount);
            b.setAdjustAmount(BigDecimal.ZERO);
            b.setFinalAmount(amount);
            b.setStatus("已确认");
            b.setLockFlag(1);
            b.setTariffVersion(rule.getVersion());
            billMapper.insert(b);

            r.setLocked(1);
            readingMapper.updateById(r);
            total = total.add(amount);
            created++;
        }
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("created", created);
        res.put("totalAmount", total);
        return res;
    }

    /** 手工调整：必须填写原因；原始金额保留，最终金额 = 原金额 + 调整额 */
    @Transactional
    public void adjust(Long id, BigDecimal adjustAmount, String reason) {
        EnergyBill b = billMapper.selectById(id);
        if (b == null) {
            throw new BizException(404, "账单不存在");
        }
        if (reason == null || reason.trim().length() < 5) {
            throw new BizException("调整原因不少于 5 个字");
        }
        if (adjustAmount == null) {
            throw new BizException("调整金额必填");
        }
        b.setAdjustAmount(adjustAmount);
        b.setFinalAmount(b.getAmount().add(adjustAmount).setScale(2, RoundingMode.HALF_UP));
        b.setStatus("已调整");
        billMapper.updateById(b);
    }

    private static boolean nz(String s) {
        return s != null && !s.isBlank();
    }

    private static long num(String s, long def) {
        try {
            return nz(s) ? Long.parseLong(s) : def;
        } catch (NumberFormatException e) {
            return def;
        }
    }
}
