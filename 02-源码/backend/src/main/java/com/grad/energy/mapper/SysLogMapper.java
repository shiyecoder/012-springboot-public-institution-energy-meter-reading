package com.grad.energy.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.energy.entity.SysLog;
import org.apache.ibatis.annotations.Mapper;

/** 操作日志 数据访问，通用 CRUD 由 MyBatis-Plus 提供。 */
@Mapper
public interface SysLogMapper extends BaseMapper<SysLog> {
}
