package com.grad.energy.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.grad.energy.common.BizException;
import com.grad.energy.common.PageResult;
import com.grad.energy.common.UserContext;
import com.grad.energy.entity.Building;
import com.grad.energy.entity.EnergyUnit;
import com.grad.energy.entity.Meter;
import com.grad.energy.entity.ReadingTask;
import com.grad.energy.mapper.BuildingMapper;
import com.grad.energy.mapper.EnergyUnitMapper;
import com.grad.energy.mapper.MeterMapper;
import com.grad.energy.mapper.ReadingTaskMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** 空间与计量台账：建筑、用能单元、表计。 */
@Service
@RequiredArgsConstructor
public class MeterService {

    private final MeterMapper meterMapper;
    private final BuildingMapper buildingMapper;
    private final EnergyUnitMapper unitMapper;
    private final ReadingTaskMapper taskMapper;

    public List<Building> buildings() {
        return buildingMapper.selectList(Wrappers.<Building>lambdaQuery().orderByAsc(Building::getId));
    }

    public List<EnergyUnit> units(Long buildingId) {
        return unitMapper.selectList(Wrappers.<EnergyUnit>lambdaQuery()
                .eq(buildingId != null, EnergyUnit::getBuildingId, buildingId)
                .orderByAsc(EnergyUnit::getId));
    }

    /** 分页查询：支持建筑、能源类型、状态、周期、异常标记、关键字。 */
    public PageResult<Map<String, Object>> page(Map<String, String> q) {
        long page = parseLong(q.get("page"), 1);
        long size = parseLong(q.get("size"), 10);
        QueryWrapper<Meter> w = new QueryWrapper<>();
        w.eq("deleted", 0);
        if (notBlank(q.get("buildingId"))) {
            w.eq("building_id", Long.parseLong(q.get("buildingId")));
        }
        if (notBlank(q.get("energyType"))) {
            w.eq("energy_type", q.get("energyType"));
        }
        if (notBlank(q.get("status"))) {
            w.eq("status", q.get("status"));
        }
        if (notBlank(q.get("cycleType"))) {
            w.eq("cycle_type", q.get("cycleType"));
        }
        if (notBlank(q.get("abnormalFlag"))) {
            w.eq("abnormal_flag", q.get("abnormalFlag"));
        }
        if (notBlank(q.get("keyword"))) {
            w.and(x -> x.like("meter_code", q.get("keyword")).or().like("install_location", q.get("keyword")));
        }
        // 数据范围：部门联络员只看本组织建筑
        if ("DEPT".equals(UserContext.dataScope()) && UserContext.orgId() != null) {
            List<Long> bids = buildingMapper.selectList(Wrappers.<Building>lambdaQuery()
                            .eq(Building::getOrgId, UserContext.orgId()))
                    .stream().map(Building::getId).toList();
            if (bids.isEmpty()) {
                return PageResult.of(0, page, size, List.of());
            }
            w.in("building_id", bids);
        }
        w.orderByDesc("update_time");
        Page<Meter> p = meterMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = p.getRecords().stream().map(m -> {
            Map<String, Object> r = new HashMap<>();
            r.put("id", m.getId());
            r.put("meterCode", m.getMeterCode());
            r.put("meterName", m.getMeterName());
            r.put("energyType", m.getEnergyType());
            r.put("buildingId", m.getBuildingId());
            Building b = buildingMapper.selectById(m.getBuildingId());
            r.put("buildingName", b == null ? "—" : b.getBuildingName());
            r.put("installLocation", m.getInstallLocation());
            r.put("unitName", m.getUnitName());
            r.put("ratio", m.getRatio());
            r.put("lastReading", m.getLastReading());
            r.put("status", m.getStatus());
            r.put("cycleType", m.getCycleType());
            r.put("abnormalFlag", m.getAbnormalFlag());
            return r;
        }).toList();
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    public Map<String, Object> detail(Long id) {
        Meter m = meterMapper.selectById(id);
        if (m == null) {
            throw new BizException(404, "表计不存在");
        }
        Map<String, Object> r = new HashMap<>();
        r.put("meter", m);
        r.put("building", buildingMapper.selectById(m.getBuildingId()));
        r.put("unit", m.getUnitId() == null ? null : unitMapper.selectById(m.getUnitId()));
        r.put("tasks", taskMapper.selectList(Wrappers.<ReadingTask>lambdaQuery()
                .eq(ReadingTask::getMeterId, id).orderByDesc(ReadingTask::getId).last("limit 12")));
        return r;
    }

    public Long save(Meter m) {
        validate(m);
        Long dup = meterMapper.selectCount(Wrappers.<Meter>lambdaQuery().eq(Meter::getMeterCode, m.getMeterCode().trim()));
        if (dup != null && dup > 0) {
            throw new BizException(409, "表计编号已存在：" + m.getMeterCode());
        }
        m.setMeterCode(m.getMeterCode().trim());
        meterMapper.insert(m);
        return m.getId();
    }

    public void update(Meter m) {
        Meter db = meterMapper.selectById(m.getId());
        if (db == null) {
            throw new BizException(404, "表计不存在");
        }
        // 并发校验：前端带回来的 updateTime 与库中不一致说明已被他人修改
        if (m.getUpdateTime() != null && db.getUpdateTime() != null
                && !m.getUpdateTime().equals(db.getUpdateTime())) {
            throw new BizException(409, "该表计已被他人更新，请刷新后重试");
        }
        validate(m);
        m.setCreateTime(null);
        meterMapper.updateById(m);
    }

    /** 删除前校验是否已被抄表任务引用，避免主数据被业务单据悬空引用。 */
    public void delete(Long id) {
        Long used = taskMapper.selectCount(Wrappers.<ReadingTask>lambdaQuery().eq(ReadingTask::getMeterId, id));
        if (used != null && used > 0) {
            throw new BizException("该表计已有 " + used + " 条抄表任务，不能删除，可改为停用");
        }
        meterMapper.deleteById(id);
    }

    public void changeStatus(Long id, String status) {
        Meter m = meterMapper.selectById(id);
        if (m == null) {
            throw new BizException(404, "表计不存在");
        }
        m.setStatus(status);
        meterMapper.updateById(m);
    }

    private void validate(Meter m) {
        if (m.getMeterCode() == null || m.getMeterCode().isBlank()) {
            throw new BizException("表计编号必填");
        }
        if (m.getMeterCode().trim().length() > 50) {
            throw new BizException("表计编号不超过 50 个字符");
        }
        if (m.getBuildingId() == null) {
            throw new BizException("所属建筑必填");
        }
        if (m.getInstallLocation() == null || m.getInstallLocation().isBlank()) {
            throw new BizException("安装位置必填");
        }
        if (m.getUnitName() == null || m.getUnitName().isBlank()) {
            throw new BizException("计量单位必填");
        }
        if (m.getRatio() == null || m.getRatio().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BizException("倍率必须为正数");
        }
        if (m.getEnergyType() == null || !List.of("ELEC", "WATER", "GAS", "COOL").contains(m.getEnergyType())) {
            throw new BizException("能源类型不在字典范围内");
        }
    }

    private static boolean notBlank(String s) {
        return s != null && !s.isBlank();
    }

    private static long parseLong(String s, long def) {
        try {
            return notBlank(s) ? Long.parseLong(s) : def;
        } catch (NumberFormatException e) {
            return def;
        }
    }
}
