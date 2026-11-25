package com.grad.energy.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.energy.entity.ReadingTask;
import org.apache.ibatis.annotations.Mapper;

/** 抄表任务 数据访问，通用 CRUD 由 MyBatis-Plus 提供。 */
@Mapper
public interface ReadingTaskMapper extends BaseMapper<ReadingTask> {
}
