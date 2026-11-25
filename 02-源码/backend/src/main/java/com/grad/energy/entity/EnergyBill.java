package com.grad.energy.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;

/** energy_bill：费用台账 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("energy_bill")
public class EnergyBill extends BaseEntity {

    /** 账单编号 */
    private String billNo;

    /** 建筑 */
    private Long buildingId;

    /** 表计 */
    private Long meterId;

    /** 能源类型 */
    private String energyType;

    /** 周期 */
    private String period;

    /** 用量 */
    private BigDecimal usageAmount;

    /** 单价 */
    private BigDecimal unitPrice;

    /** 金额 */
    private BigDecimal amount;

    /** 调整金额 */
    private BigDecimal adjustAmount;

    /** 结算金额 */
    private BigDecimal finalAmount;

    /** 状态 */
    private String status;

    /** 锁定标记 */
    private Integer lockFlag;

    /** 计费规则版本 */
    private String tariffVersion;
}
