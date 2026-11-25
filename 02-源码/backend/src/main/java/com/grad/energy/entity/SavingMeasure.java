package com.grad.energy.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;
import java.time.LocalDate;

/** saving_measure：节能措施 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("saving_measure")
public class SavingMeasure extends BaseEntity {

    /** 措施编号 */
    private String measureNo;

    /** 措施名称 */
    private String measureName;

    /** 建筑 */
    private Long buildingId;

    /** 措施内容 */
    private String content;

    /** 投入万元 */
    private BigDecimal investAmount;

    /** 计划开始 */
    private LocalDate planStart;

    /** 计划结束 */
    private LocalDate planEnd;

    /** 目标节能tce */
    private BigDecimal targetSaving;

    /** 实际节能tce */
    private BigDecimal actualSaving;

    /** 状态 */
    private String status;

    /** 负责人 */
    private Long ownerId;
}
