package com.grad.energy.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.energy.entity.EnergyUnit;
import org.apache.ibatis.annotations.Mapper;

/** 用能单元 数据访问，通用 CRUD 由 MyBatis-Plus 提供。 */
@Mapper
public interface EnergyUnitMapper extends BaseMapper<EnergyUnit> {
}
