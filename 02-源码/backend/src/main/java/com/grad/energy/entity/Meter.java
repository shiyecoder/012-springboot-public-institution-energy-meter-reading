package com.grad.energy.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;
import java.time.LocalDate;

/** meter：能耗表计 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meter")
public class Meter extends BaseEntity {

    /** 表计编号 */
    private String meterCode;

    /** 表计名称 */
    private String meterName;

    /** ELEC/WATER/GAS/COOL */
    private String energyType;

    /** 所属建筑 */
    private Long buildingId;

    /** 所属用能单元 */
    private Long unitId;

    /** 安装位置 */
    private String installLocation;

    /** 计量单位 */
    private String unitName;

    /** 倍率 */
    private BigDecimal ratio;

    /** 上期读数 */
    private BigDecimal lastReading;

    /** 在用/停用/待检定 */
    private String status;

    /** MONTH/QUARTER */
    private String cycleType;

    /** 异常标记 */
    private String abnormalFlag;

    /** 安装日期 */
    private LocalDate installDate;
}
