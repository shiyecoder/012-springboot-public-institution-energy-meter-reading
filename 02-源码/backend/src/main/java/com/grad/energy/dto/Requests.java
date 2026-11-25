package com.grad.energy.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/** 请求对象集合：按业务场景分组，避免为每个字段单独建类。 */
public class Requests {

    @Data
    public static class Login {
        private String username;
        private String password;
    }

    @Data
    public static class Password {
        private String oldPassword;
        private String newPassword;
    }

    @Data
    public static class Profile {
        private String realName;
        private String phone;
        private String email;
        private String avatar;
    }

    @Data
    public static class PlanGen {
        private String period;
        private Long buildingId;
    }

    @Data
    public static class ReadingSubmit {
        private Long taskId;
        private BigDecimal currReading;
        private LocalDateTime readTime;
        private String photoPath;
        private String meterStatus;
        private String remark;
    }

    @Data
    public static class Review {
        private String action; // PASS / REJECT / EXCEPTION
        private String note;
    }

    @Data
    public static class ExceptionHandle {
        private String action; // CLOSE / IGNORE / REPAIR
        private String cause;
        private String note;
    }

    @Data
    public static class BillAdjust {
        private BigDecimal adjustAmount;
        private String reason;
    }

    @Data
    public static class RuleSave {
        private Long id;
        private String ruleName;
        private Map<String, BigDecimal> weights;
        private Map<String, BigDecimal> thresholds;
    }

    @Data
    public static class ScoreAdjust {
        private String level;
        private String reason;
    }

    @Data
    public static class EvaluateReq {
        private Long buildingId;
        private Long meterId;
        private String period;
        private String energyType;
    }

    @Data
    public static class QuotaSave {
        private Long id;
        private String targetType;
        private Long targetId;
        private String targetName;
        private String energyType;
        private String periodType;
        private BigDecimal quotaValue;
        private Integer year;
    }

    @Data
    public static class MeasureSave {
        private Long id;
        private String measureName;
        private Long buildingId;
        private String content;
        private BigDecimal investAmount;
        private LocalDate planStart;
        private LocalDate planEnd;
        private BigDecimal targetSaving;
        private BigDecimal actualSaving;
        private String status;
    }

    @Data
    public static class UserSave {
        private Long id;
        private String username;
        private String realName;
        private String roleCode;
        private Long orgId;
        private String phone;
        private String email;
        private String status;
        private String password;
    }

    @Data
    public static class RoleMenuSave {
        private String roleCode;
        private List<Long> menuIds;
    }
}
