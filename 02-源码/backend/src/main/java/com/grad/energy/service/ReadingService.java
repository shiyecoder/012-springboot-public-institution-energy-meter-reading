package com.grad.energy.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.grad.energy.common.BizException;
import com.grad.energy.common.PageResult;
import com.grad.energy.common.Status;
import com.grad.energy.common.UserContext;
import com.grad.energy.dto.Requests;
import com.grad.energy.entity.*;
import com.grad.energy.mapper.*;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * 抄表作业：任务生成 → 现场录入 → 数据复核 → 异常处置 → 归档。
 * 所有状态流转均在后端校验，前端按钮只做提示。
 */
@Service
@RequiredArgsConstructor
public class ReadingService {

    private final ReadingTaskMapper taskMapper;
    private final MeterReadingMapper readingMapper;
    private final MeterMapper meterMapper;
    private final BuildingMapper buildingMapper;
    private final EnergyExceptionMapper exceptionMapper;
    private final SysUserMapper userMapper;

    /** 偏差阈值：超出近 6 期均值 20% 需复核 */
    private static final BigDecimal DEV_LIMIT = new BigDecimal("20");

    public PageResult<Map<String, Object>> taskPage(Map<String, String> q) {
        long page = num(q.get("page"), 1);
        long size = num(q.get("size"), 10);
        QueryWrapper<ReadingTask> w = new QueryWrapper<>();
        w.eq("deleted", 0);
        if (nz(q.get("period"))) {
            w.eq("period", q.get("period"));
        }
        if (nz(q.get("status"))) {
            w.eq("status", q.get("status"));
        }
        if (nz(q.get("buildingId"))) {
            w.eq("building_id", Long.parseLong(q.get("buildingId")));
        }
        if ("SELF".equals(UserContext.dataScope())) {
            w.eq("reader_id", UserContext.userId());
        }
        if (nz(q.get("readerId"))) {
            w.eq("reader_id", Long.parseLong(q.get("readerId")));
        }
        w.orderByDesc("deadline").orderByDesc("id");
        Page<ReadingTask> p = taskMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (ReadingTask t : p.getRecords()) {
            rows.add(taskVo(t));
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    public Map<String, Object> taskVo(ReadingTask t) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("id", t.getId());
        r.put("taskNo", t.getTaskNo());
        r.put("period", t.getPeriod());
        r.put("planDate", t.getPlanDate());
        r.put("deadline", t.getDeadline());
        r.put("status", t.getStatus());
        r.put("statusLabel", Status.label(t.getStatus()));
        r.put("source", t.getSource());
        r.put("remark", t.getRemark());
        Meter m = meterMapper.selectById(t.getMeterId());
        if (m != null) {
            r.put("meterCode", m.getMeterCode());
            r.put("meterName", m.getMeterName());
            r.put("energyType", m.getEnergyType());
            r.put("ratio", m.getRatio());
            r.put("lastReading", m.getLastReading());
            r.put("installLocation", m.getInstallLocation());
        }
        Building b = buildingMapper.selectById(t.getBuildingId());
        r.put("buildingName", b == null ? "—" : b.getBuildingName());
        if (t.getReaderId() != null) {
            SysUser u = userMapper.selectById(t.getReaderId());
            r.put("readerName", u == null ? "—" : u.getRealName());
        }
        return r;
    }

    /** 按月度和区域生成任务：同一表计同周期不重复生成 */
    @Transactional
    public int generatePlan(String period, Long buildingId) {
        if (period == null || !period.matches("\\d{4}-\\d{2}")) {
            throw new BizException("周期格式应为 yyyy-MM");
        }
        List<Meter> meters = meterMapper.selectList(Wrappers.<Meter>lambdaQuery()
                .eq(Meter::getStatus, "在用")
                .eq(buildingId != null, Meter::getBuildingId, buildingId));
        int created = 0;
        LocalDate plan = LocalDate.parse(period + "-25");
        for (Meter m : meters) {
            Long exists = taskMapper.selectCount(Wrappers.<ReadingTask>lambdaQuery()
                    .eq(ReadingTask::getMeterId, m.getId()).eq(ReadingTask::getPeriod, period));
            if (exists != null && exists > 0) {
                continue;
            }
            ReadingTask t = new ReadingTask();
            t.setTaskNo("TK-" + period.replace("-", "") + "-" + String.format("%04d", m.getId() % 10000));
            t.setMeterId(m.getId());
            t.setBuildingId(m.getBuildingId());
            t.setPeriod(period);
            t.setPlanDate(plan);
            t.setDeadline(plan.plusDays(3));
            t.setReaderId(1L + (m.getId() % 3));
            t.setStatus(Status.GENERATED);
            t.setSource("PLAN");
            taskMapper.insert(t);
            created++;
        }
        return created;
    }

    public void assign(Long taskId, Long readerId) {
        ReadingTask t = mustTask(taskId);
        if (Status.isFinal(t.getStatus())) {
            throw new BizException("已归档或作废的任务不能改派");
        }
        t.setReaderId(readerId);
        taskMapper.updateById(t);
    }

    /** 现场抄表提交：校验读数倒退、计算用量与偏差、生成待复核记录 */
    @Transactional
    public Map<String, Object> submit(Requests.ReadingSubmit req) {
        ReadingTask t = mustTask(req.getTaskId());
        if (!Status.GENERATED.equals(t.getStatus()) && !Status.READING.equals(t.getStatus())
                && !Status.REJECTED.equals(t.getStatus())) {
            throw new BizException("当前任务状态为「" + Status.label(t.getStatus()) + "」，不可录入");
        }
        if (!UserContext.isAdmin() && t.getReaderId() != null
                && !t.getReaderId().equals(UserContext.userId())) {
            throw new BizException(403, "该任务未派给你，不能录入");
        }
        Meter m = meterMapper.selectById(t.getMeterId());
        if (m == null) {
            throw new BizException("表计不存在");
        }
        if (req.getCurrReading() == null) {
            throw new BizException("本期读数必填");
        }
        if (req.getPhotoPath() == null || req.getPhotoPath().isBlank()) {
            throw new BizException("表盘照片必填，请通过上传组件提交");
        }
        BigDecimal prev = m.getLastReading() == null ? BigDecimal.ZERO : m.getLastReading();
        if (req.getCurrReading().compareTo(prev) < 0) {
            throw new BizException("本期读数 " + req.getCurrReading() + " 小于上期读数 " + prev + "，请核对表盘");
        }
        BigDecimal ratio = m.getRatio() == null ? BigDecimal.ONE : m.getRatio();
        BigDecimal usage = req.getCurrReading().subtract(prev).multiply(ratio).setScale(2, RoundingMode.HALF_UP);
        BigDecimal avg = historyAvg(m.getId(), t.getPeriod());
        BigDecimal dev = BigDecimal.ZERO;
        if (avg.compareTo(BigDecimal.ZERO) > 0) {
            dev = usage.subtract(avg).multiply(new BigDecimal("100"))
                    .divide(avg, 2, RoundingMode.HALF_UP);
        }
        MeterReading r = new MeterReading();
        r.setReadingNo("RD-" + t.getPeriod().replace("-", "") + "-" + String.format("%04d", t.getId() % 10000));
        r.setTaskId(t.getId());
        r.setMeterId(m.getId());
        r.setPeriod(t.getPeriod());
        r.setPrevReading(prev);
        r.setCurrReading(req.getCurrReading());
        r.setUsageAmount(usage);
        r.setReadTime(req.getReadTime() == null ? LocalDateTime.now() : req.getReadTime());
        r.setPhotoPath(req.getPhotoPath());
        r.setMeterStatus(req.getMeterStatus() == null ? "正常" : req.getMeterStatus());
        r.setRemark(req.getRemark());
        r.setDeviationRate(dev);
        r.setReviewStatus("PENDING");
        r.setLocked(0);
        readingMapper.insert(r);

        m.setLastReading(req.getCurrReading());
        meterMapper.updateById(m);

        t.setStatus(Status.REVIEWING);
        taskMapper.updateById(t);

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("readingId", r.getId());
        res.put("usage", usage);
        res.put("deviation", dev);
        // 偏差超阈值：自动建异常单并转异常处理
        if (dev.abs().compareTo(DEV_LIMIT) > 0) {
            EnergyException e = new EnergyException();
            e.setExceptionNo("EX-" + t.getPeriod().replace("-", "") + "-" + String.format("%04d", r.getId() % 10000));
            e.setMeterId(m.getId());
            e.setReadingId(r.getId());
            e.setBuildingId(t.getBuildingId());
            e.setExceptionType(dev.compareTo(BigDecimal.ZERO) > 0 ? "SURGE" : "DROP");
            e.setLevel(dev.abs().compareTo(new BigDecimal("30")) > 0 ? Status.LV_HIGH : Status.LV_MID);
            e.setTriggerRule("本期用量 " + usage + "，较近 6 期均值 " + avg + " 偏离 " + dev + "%，超过 "
                    + DEV_LIMIT + "% 阈值");
            e.setDescription("抄表偏差自动预警");
            e.setStatus("OPEN");
            exceptionMapper.insert(e);
            res.put("exceptionNo", e.getExceptionNo());
        }
        return res;
    }

    /** 数据复核：通过后归档，驳回退回重新录入，转异常进入异常处理 */
    @Transactional
    public void review(Long readingId, String action, String note) {
        MeterReading r = readingMapper.selectById(readingId);
        if (r == null) {
            throw new BizException(404, "抄表记录不存在");
        }
        if (Integer.valueOf(1).equals(r.getLocked())) {
            throw new BizException("该记录已被账单引用锁定，调整需走审批");
        }
        ReadingTask t = mustTask(r.getTaskId());
        if (!Status.REVIEWING.equals(t.getStatus())) {
            throw new BizException("任务当前状态为「" + Status.label(t.getStatus()) + "」，不能复核");
        }
        if ("REJECT".equalsIgnoreCase(action) && (note == null || note.trim().length() < 5)) {
            throw new BizException("退回原因不少于 5 个字");
        }
        r.setReviewerId(UserContext.userId());
        r.setReviewTime(LocalDateTime.now());
        r.setReviewNote(note);
        switch (action == null ? "" : action.toUpperCase()) {
            case "PASS" -> {
                r.setReviewStatus("PASS");
                t.setStatus(Status.ARCHIVED);
                Meter m = meterMapper.selectById(r.getMeterId());
                if (m != null) {
                    m.setAbnormalFlag("正常");
                    meterMapper.updateById(m);
                }
            }
            case "REJECT" -> {
                r.setReviewStatus("REJECT");
                t.setStatus(Status.REJECTED);
                Meter m = meterMapper.selectById(r.getMeterId());
                if (m != null) {
                    m.setLastReading(r.getPrevReading());
                    meterMapper.updateById(m);
                }
            }
            case "EXCEPTION" -> {
                r.setReviewStatus("PENDING");
                t.setStatus(Status.EXCEPTION);
                EnergyException e = new EnergyException();
                e.setExceptionNo("EX-" + r.getPeriod().replace("-", "") + "-M" + r.getId());
                e.setMeterId(r.getMeterId());
                e.setReadingId(r.getId());
                e.setBuildingId(t.getBuildingId());
                e.setExceptionType("SURGE");
                e.setLevel(Status.LV_MID);
                e.setTriggerRule("人工复核转异常：" + (note == null ? "复核存疑" : note));
                e.setStatus("OPEN");
                exceptionMapper.insert(e);
            }
            default -> throw new BizException("不支持的复核动作：" + action);
        }
        readingMapper.updateById(r);
        taskMapper.updateById(t);
    }

    public PageResult<Map<String, Object>> readingPage(Map<String, String> q) {
        long page = num(q.get("page"), 1);
        long size = num(q.get("size"), 10);
        QueryWrapper<MeterReading> w = new QueryWrapper<>();
        w.eq("deleted", 0);
        if (nz(q.get("period"))) {
            w.eq("period", q.get("period"));
        }
        if (nz(q.get("reviewStatus"))) {
            w.eq("review_status", q.get("reviewStatus"));
        }
        if (nz(q.get("meterId"))) {
            w.eq("meter_id", Long.parseLong(q.get("meterId")));
        }
        if (nz(q.get("keyword"))) {
            w.like("reading_no", q.get("keyword"));
        }
        w.orderByDesc("read_time");
        Page<MeterReading> p = readingMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (MeterReading r : p.getRecords()) {
            Map<String, Object> x = new LinkedHashMap<>();
            x.put("id", r.getId());
            x.put("readingNo", r.getReadingNo());
            x.put("period", r.getPeriod());
            x.put("prevReading", r.getPrevReading());
            x.put("currReading", r.getCurrReading());
            x.put("usageAmount", r.getUsageAmount());
            x.put("readTime", r.getReadTime());
            x.put("photoPath", r.getPhotoPath());
            x.put("deviationRate", r.getDeviationRate());
            x.put("reviewStatus", r.getReviewStatus());
            x.put("locked", r.getLocked());
            x.put("reviewNote", r.getReviewNote());
            Meter m = meterMapper.selectById(r.getMeterId());
            if (m != null) {
                x.put("meterCode", m.getMeterCode());
                x.put("energyType", m.getEnergyType());
                Building b = buildingMapper.selectById(m.getBuildingId());
                x.put("buildingName", b == null ? "—" : b.getBuildingName());
            }
            ReadingTask t = r.getTaskId() == null ? null : taskMapper.selectById(r.getTaskId());
            x.put("taskStatus", t == null ? null : t.getStatus());
            x.put("taskStatusLabel", t == null ? null : Status.label(t.getStatus()));
            rows.add(x);
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    public PageResult<Map<String, Object>> exceptionPage(Map<String, String> q) {
        long page = num(q.get("page"), 1);
        long size = num(q.get("size"), 10);
        QueryWrapper<EnergyException> w = new QueryWrapper<>();
        w.eq("deleted", 0);
        if (nz(q.get("status"))) {
            w.eq("status", q.get("status"));
        }
        if (nz(q.get("exceptionType"))) {
            w.eq("exception_type", q.get("exceptionType"));
        }
        w.orderByAsc("status").orderByDesc("id");
        Page<EnergyException> p = exceptionMapper.selectPage(new Page<>(page, size), w);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (EnergyException e : p.getRecords()) {
            Map<String, Object> x = new LinkedHashMap<>();
            x.put("id", e.getId());
            x.put("exceptionNo", e.getExceptionNo());
            x.put("exceptionType", e.getExceptionType());
            x.put("level", e.getLevel());
            x.put("triggerRule", e.getTriggerRule());
            x.put("description", e.getDescription());
            x.put("status", e.getStatus());
            x.put("cause", e.getCause());
            x.put("handleNote", e.getHandleNote());
            x.put("closeTime", e.getCloseTime());
            x.put("createTime", e.getCreateTime());
            Meter m = meterMapper.selectById(e.getMeterId());
            if (m != null) {
                x.put("meterCode", m.getMeterCode());
                x.put("energyType", m.getEnergyType());
                Building b = buildingMapper.selectById(m.getBuildingId());
                x.put("buildingName", b == null ? "—" : b.getBuildingName());
            }
            rows.add(x);
        }
        return PageResult.of(p.getTotal(), page, size, rows);
    }

    @Transactional
    public void handleException(Long id, Requests.ExceptionHandle req) {
        EnergyException e = exceptionMapper.selectById(id);
        if (e == null) {
            throw new BizException(404, "异常单不存在");
        }
        if ("CLOSED".equals(e.getStatus())) {
            throw new BizException("异常单已关闭");
        }
        if (req.getNote() == null || req.getNote().trim().length() < 5) {
            throw new BizException("处置说明不少于 5 个字");
        }
        e.setCause(req.getCause());
        e.setHandleNote(req.getNote());
        e.setHandlerId(UserContext.userId());
        if ("IGNORE".equalsIgnoreCase(req.getAction())) {
            e.setStatus("IGNORED");
        } else if ("REPAIR".equalsIgnoreCase(req.getAction())) {
            e.setStatus("HANDLING");
        } else {
            e.setStatus("CLOSED");
            e.setCloseTime(LocalDateTime.now());
            MeterReading r = e.getReadingId() == null ? null : readingMapper.selectById(e.getReadingId());
            if (r != null && r.getTaskId() != null) {
                ReadingTask t = taskMapper.selectById(r.getTaskId());
                if (t != null && Status.EXCEPTION.equals(t.getStatus())) {
                    t.setStatus(Status.ARCHIVED);
                    taskMapper.updateById(t);
                }
                r.setReviewStatus("PASS");
                readingMapper.updateById(r);
            }
            Meter m = meterMapper.selectById(e.getMeterId());
            if (m != null) {
                m.setAbnormalFlag("正常");
                meterMapper.updateById(m);
            }
        }
        exceptionMapper.updateById(e);
    }

    /**
     * Excel 抄表导入：模板列 = 表计编号 | 本期读数 | 抄表时间 | 备注。
     * 逐行校验并返回行号与失败原因，成功的行照常入库。
     */
    public Map<String, Object> importExcel(MultipartFile file, String period) {
        if (file == null || file.isEmpty()) {
            throw new BizException("请选择要导入的 Excel 文件");
        }
        List<Map<String, Object>> errors = new ArrayList<>();
        int ok = 0;
        try (InputStream in = file.getInputStream(); Workbook wb = new XSSFWorkbook(in)) {
            Sheet sheet = wb.getSheetAt(0);
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null) {
                    continue;
                }
                String code = cell(row.getCell(0));
                String curr = cell(row.getCell(1));
                if (code.isBlank() && curr.isBlank()) {
                    continue;
                }
                int rowNo = i + 1;
                try {
                    Meter m = meterMapper.selectOne(Wrappers.<Meter>lambdaQuery()
                            .eq(Meter::getMeterCode, code).last("limit 1"));
                    if (m == null) {
                        throw new BizException("表计编号不存在：" + code);
                    }
                    ReadingTask t = taskMapper.selectOne(Wrappers.<ReadingTask>lambdaQuery()
                            .eq(ReadingTask::getMeterId, m.getId()).eq(ReadingTask::getPeriod, period)
                            .last("limit 1"));
                    if (t == null) {
                        throw new BizException("未找到该表计 " + period + " 的抄表任务");
                    }
                    Requests.ReadingSubmit s = new Requests.ReadingSubmit();
                    s.setTaskId(t.getId());
                    s.setCurrReading(new BigDecimal(curr));
                    s.setPhotoPath("/uploads/seed/meter/" + String.format("%02d", (m.getId() % 8) + 1) + ".jpg");
                    s.setMeterStatus("正常");
                    s.setRemark("Excel 批量导入");
                    submit(s);
                    ok++;
                } catch (NumberFormatException ex) {
                    errors.add(Map.of("row", rowNo, "reason", "本期读数不是有效数字"));
                } catch (Exception ex) {
                    errors.add(Map.of("row", rowNo, "reason", ex.getMessage()));
                }
            }
        } catch (Exception e) {
            throw new BizException("Excel 解析失败：" + e.getMessage());
        }
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("success", ok);
        res.put("failed", errors.size());
        res.put("errors", errors);
        return res;
    }

    private static String cell(Cell c) {
        if (c == null) {
            return "";
        }
        return switch (c.getCellType()) {
            case NUMERIC -> BigDecimal.valueOf(c.getNumericCellValue()).stripTrailingZeros().toPlainString();
            case STRING -> c.getStringCellValue().trim();
            default -> "";
        };
    }

    private BigDecimal historyAvg(Long meterId, String period) {
        List<MeterReading> list = readingMapper.selectList(Wrappers.<MeterReading>lambdaQuery()
                .eq(MeterReading::getMeterId, meterId).lt(MeterReading::getPeriod, period)
                .orderByDesc(MeterReading::getPeriod).last("limit 6"));
        if (list.isEmpty()) {
            return BigDecimal.ZERO;
        }
        BigDecimal sum = BigDecimal.ZERO;
        for (MeterReading r : list) {
            sum = sum.add(r.getUsageAmount() == null ? BigDecimal.ZERO : r.getUsageAmount());
        }
        return sum.divide(BigDecimal.valueOf(list.size()), 2, RoundingMode.HALF_UP);
    }

    private ReadingTask mustTask(Long id) {
        ReadingTask t = taskMapper.selectById(id);
        if (t == null) {
            throw new BizException(404, "抄表任务不存在");
        }
        return t;
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
