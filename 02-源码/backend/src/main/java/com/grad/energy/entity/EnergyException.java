package com.grad.energy.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.time.LocalDateTime;

/** energy_exception：异常单 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("energy_exception")
public class EnergyException extends BaseEntity {

    /** 异常编号 */
    private String exceptionNo;

    /** 表计 */
    private Long meterId;

    /** 抄表记录 */
    private Long readingId;

    /** 建筑 */
    private Long buildingId;

    /** SURGE/DROP/FLAT/DAMAGE/CASCADE */
    private String exceptionType;

    /** HIGH/MID/LOW */
    private String level;

    /** 触发规则说明 */
    private String triggerRule;

    /** 异常描述 */
    private String description;

    /** 处理人 */
    private Long handlerId;

    /** OPEN/HANDLING/CLOSED/IGNORED */
    private String status;

    /** 原因 */
    private String cause;

    /** 处置说明 */
    private String handleNote;

    /** 关闭时间 */
    private LocalDateTime closeTime;
}
