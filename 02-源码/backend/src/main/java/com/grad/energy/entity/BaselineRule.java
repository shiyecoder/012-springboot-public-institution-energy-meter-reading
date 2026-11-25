package com.grad.energy.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.time.LocalDateTime;

/** baseline_rule：基线识别规则 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("baseline_rule")
public class BaselineRule extends BaseEntity {

    /** 规则名称 */
    private String ruleName;

    /** 版本 */
    private String version;

    /** 权重JSON */
    private String weightsJson;

    /** 阈值JSON */
    private String thresholdJson;

    /** ENABLED/DISABLED */
    private String status;

    /** 生效时间 */
    private LocalDateTime effectiveTime;

    /** 创建人 */
    private String createBy;
}
