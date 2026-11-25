package com.grad.energy.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.energy.entity.MeterReading;
import org.apache.ibatis.annotations.Mapper;

/** 抄表记录 数据访问，通用 CRUD 由 MyBatis-Plus 提供。 */
@Mapper
public interface MeterReadingMapper extends BaseMapper<MeterReading> {
}
