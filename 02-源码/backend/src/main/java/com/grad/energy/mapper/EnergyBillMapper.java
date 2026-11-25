package com.grad.energy.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.energy.entity.EnergyBill;
import org.apache.ibatis.annotations.Mapper;

/** 费用台账 数据访问，通用 CRUD 由 MyBatis-Plus 提供。 */
@Mapper
public interface EnergyBillMapper extends BaseMapper<EnergyBill> {
}
