package com.grad.energy.common;

import java.util.List;

/**
 * 抄表任务状态机与业务常量。
 *
 * 主流程：任务生成(GENERATED) → 现场抄表(READING) → 数据复核(REVIEWING)
 *        → 异常处理(EXCEPTION) → 周期归档(ARCHIVED)
 * 分支：复核不通过退回 REJECTED（重新录入后回到 READING）；漏抄 MISSED；作废 CANCELLED。
 *
 * 后端强制校验（不依赖前端隐藏按钮）：
 *  1. 仅 READER 可执行现场录入，且只能操作派给本人的任务；
 *  2. 本期读数不得小于上期读数，否则直接拒绝；
 *  3. 偏差超过阈值时必须由 ENERGY_ADMIN 复核，READER 不能自行确认；
 *  4. 账单生成后锁定抄表记录（meter_reading.locked=1），调整必须走审批；
 *  5. 已归档任务不可再变更。
 */
public final class Status {

    public static final String GENERATED = "GENERATED";
    public static final String READING = "READING";
    public static final String REVIEWING = "REVIEWING";
    public static final String EXCEPTION = "EXCEPTION";
    public static final String ARCHIVED = "ARCHIVED";
    public static final String REJECTED = "REJECTED";
    public static final String MISSED = "MISSED";
    public static final String CANCELLED = "CANCELLED";

    public static final String LV_HIGH = "HIGH";
    public static final String LV_MID = "MID";
    public static final String LV_LOW = "LOW";

    private Status() {}

    public static List<String> all() {
        return List.of(GENERATED, READING, REVIEWING, EXCEPTION, ARCHIVED, REJECTED, MISSED, CANCELLED);
    }

    public static String label(String code) {
        return switch (code == null ? "" : code) {
            case GENERATED -> "待执行";
            case READING -> "现场抄表";
            case REVIEWING -> "待复核";
            case EXCEPTION -> "异常处理";
            case ARCHIVED -> "已归档";
            case REJECTED -> "已退回";
            case MISSED -> "漏抄";
            case CANCELLED -> "已作废";
            default -> code;
        };
    }

    public static String levelLabel(String code) {
        return switch (code == null ? "" : code) {
            case LV_HIGH -> "突增";
            case LV_MID -> "偏高";
            case LV_LOW -> "正常";
            default -> code;
        };
    }

    /** 主流程正向下一节点 */
    public static String next(String status) {
        return switch (status == null ? "" : status) {
            case GENERATED -> READING;
            case READING -> REVIEWING;
            case REVIEWING -> ARCHIVED;
            case EXCEPTION -> REVIEWING;
            default -> null;
        };
    }

    public static boolean isFinal(String status) {
        return ARCHIVED.equals(status) || CANCELLED.equals(status);
    }
}
