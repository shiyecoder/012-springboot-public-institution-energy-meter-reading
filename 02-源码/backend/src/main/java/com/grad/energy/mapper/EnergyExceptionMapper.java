package com.grad.energy.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.energy.entity.EnergyException;
import org.apache.ibatis.annotations.Mapper;

/** 异常单 数据访问，通用 CRUD 由 MyBatis-Plus 提供。 */
@Mapper
public interface EnergyExceptionMapper extends BaseMapper<EnergyException> {
}
