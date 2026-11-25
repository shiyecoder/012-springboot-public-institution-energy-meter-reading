package com.grad.energy.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.energy.entity.BaselineScore;
import org.apache.ibatis.annotations.Mapper;

/** 基线识别计算留痕 数据访问，通用 CRUD 由 MyBatis-Plus 提供。 */
@Mapper
public interface BaselineScoreMapper extends BaseMapper<BaselineScore> {
}
