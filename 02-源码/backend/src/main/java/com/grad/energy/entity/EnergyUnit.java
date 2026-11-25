package com.grad.energy.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;

/** energy_unit：用能单元 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("energy_unit")
public class EnergyUnit extends BaseEntity {

    /** 单元编码 */
    private String unitCode;

    /** 单元名称 */
    private String unitName;

    /** 所属建筑 */
    private Long buildingId;

    /** 楼层 */
    private String floorNo;

    /** 房间范围 */
    private String roomRange;

    /** 面积㎡ */
    private BigDecimal area;

    /** 人数 */
    private Integer personCount;

    /** 负责人 */
    private Long managerId;

    /** 状态 */
    private String status;
}
