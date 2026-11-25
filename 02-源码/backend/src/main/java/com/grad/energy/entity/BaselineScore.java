package com.grad.energy.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/** baseline_score：基线识别计算留痕 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("baseline_score")
public class BaselineScore extends BaseEntity {

    /** 计算编号 */
    private String scoreNo;

    /** 建筑 */
    private Long buildingId;

    /** 表计 */
    private Long meterId;

    /** 能源类型 */
    private String energyType;

    /** 周期 */
    private String period;

    /** 规则 */
    private Long ruleId;

    /** 规则版本 */
    private String ruleVersion;

    /** 输入快照 */
    private String inputJson;

    /** 因子明细 */
    private String itemJson;

    /** 总分 */
    private BigDecimal totalScore;

    /** 等级 */
    private String level;

    /** 结论 */
    private String conclusion;

    /** 主要影响因素 */
    private String mainFactors;

    /** 未满足条件 */
    private String unmetJson;

    /** 可改进项 */
    private String improveJson;

    /** 是否采纳 */
    private Integer adoptFlag;

    /** 人工调整等级 */
    private String adjustLevel;

    /** 调整原因 */
    private String adjustReason;

    /** 调整人 */
    private String adjustBy;

    /** 调整时间 */
    private LocalDateTime adjustTime;

    /** 计算时间 */
    private LocalDateTime calcTime;
}
