package com.grad.energy.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.energy.entity.BaselineRule;
import org.apache.ibatis.annotations.Mapper;

/** 基线识别规则 数据访问，通用 CRUD 由 MyBatis-Plus 提供。 */
@Mapper
public interface BaselineRuleMapper extends BaseMapper<BaselineRule> {
}
