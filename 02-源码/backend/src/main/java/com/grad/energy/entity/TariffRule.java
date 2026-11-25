package com.grad.energy.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;
import java.time.LocalDate;

/** tariff_rule：计费规则 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("tariff_rule")
public class TariffRule extends BaseEntity {

    /** 规则名称 */
    private String ruleName;

    /** 能源类型 */
    private String energyType;

    /** FIXED/LADDER */
    private String chargeType;

    /** 单价 */
    private BigDecimal price;

    /** 阶梯配置JSON */
    private String ladderJson;

    /** 生效日期 */
    private LocalDate effectiveDate;

    /** 版本 */
    private String version;

    /** 状态 */
    private String status;
}
