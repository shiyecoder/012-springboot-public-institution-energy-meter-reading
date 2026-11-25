package com.grad.energy.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;

/** building：建筑 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("building")
public class Building extends BaseEntity {

    /** 建筑编号 */
    private String buildingCode;

    /** 建筑名称 */
    private String buildingName;

    /** 所属组织 */
    private Long orgId;

    /** SCHOOL/HOSPITAL/OFFICE/CULTURE */
    private String buildingType;

    /** 地址 */
    private String address;

    /** 建筑面积㎡ */
    private BigDecimal buildArea;

    /** 楼层数 */
    private Integer floorCount;

    /** 使用人数 */
    private Integer personCount;

    /** 责任人 */
    private String manager;

    /** 状态 */
    private String status;

    /** 建筑封面图（相对路径 /uploads/seed/building/NN.jpg） */
    private String coverImage;
}
