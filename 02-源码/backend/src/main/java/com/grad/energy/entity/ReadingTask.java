package com.grad.energy.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.time.LocalDate;

/** reading_task：抄表任务 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("reading_task")
public class ReadingTask extends BaseEntity {

    /** 任务编号 */
    private String taskNo;

    /** 表计 */
    private Long meterId;

    /** 建筑 */
    private Long buildingId;

    /** 周期 yyyy-MM */
    private String period;

    /** 计划日期 */
    private LocalDate planDate;

    /** 截止日期 */
    private LocalDate deadline;

    /** 抄表员 */
    private Long readerId;

    /** 状态 */
    private String status;

    /** PLAN/MANUAL/SUPPLEMENT */
    private String source;

    /** 备注 */
    private String remark;
}
