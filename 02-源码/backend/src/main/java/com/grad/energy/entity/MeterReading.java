package com.grad.energy.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/** meter_reading：抄表记录 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meter_reading")
public class MeterReading extends BaseEntity {

    /** 记录编号 */
    private String readingNo;

    /** 任务 */
    private Long taskId;

    /** 表计 */
    private Long meterId;

    /** 周期 */
    private String period;

    /** 上期读数 */
    private BigDecimal prevReading;

    /** 本期读数 */
    private BigDecimal currReading;

    /** 本期用量 */
    private BigDecimal usageAmount;

    /** 抄表时间 */
    private LocalDateTime readTime;

    /** 表盘照片 */
    private String photoPath;

    /** 表计状态 */
    private String meterStatus;

    /** 备注 */
    private String remark;

    /** 偏差率% */
    private BigDecimal deviationRate;

    /** 复核状态 */
    private String reviewStatus;

    /** 复核人 */
    private Long reviewerId;

    /** 复核时间 */
    private LocalDateTime reviewTime;

    /** 复核意见 */
    private String reviewNote;

    /** 账单锁定标记 */
    private Integer locked;
}
