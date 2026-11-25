package com.grad.energy.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;

/** energy_quota：能耗定额 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("energy_quota")
public class EnergyQuota extends BaseEntity {

    /** 定额编号 */
    private String quotaNo;

    /** BUILDING/DEPT */
    private String targetType;

    /** 对象ID */
    private Long targetId;

    /** 对象名称 */
    private String targetName;

    /** 能源类型 */
    private String energyType;

    /** YEAR/MONTH */
    private String periodType;

    /** 定额值 */
    private BigDecimal quotaValue;

    /** 已用量 */
    private BigDecimal usedValue;

    /** 年度 */
    private Integer year;
}
