-- ============================================================
-- 公共机构能耗抄表与节能分析系统 数据库初始化脚本
-- 数据库：new_012（通道 2 专用，勿与其他通道混用）
-- 默认账号：admin / admin123；其余账号密码 123456
-- 字符集 utf8mb4；时间字段覆盖 2026-05 ~ 2026-10 的真实跨度
-- ============================================================
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS `new_012`;
CREATE DATABASE `new_012` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `new_012`;

DROP TABLE IF EXISTS `sys_org`;
CREATE TABLE `sys_org` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `org_code` varchar(32) NOT NULL COMMENT '组织编码',
  `org_name` varchar(100) NOT NULL COMMENT '组织名称',
  `parent_id` bigint DEFAULT 0 COMMENT '上级组织',
  `org_type` varchar(20) NOT NULL COMMENT 'CAMPUS 院区 / DEPT 部门',
  `leader` varchar(50) DEFAULT NULL COMMENT '负责人',
  `phone` varchar(20) DEFAULT NULL COMMENT '联系电话',
  `sort` int DEFAULT 0 COMMENT '排序',
  `status` varchar(10) DEFAULT '启用' COMMENT '状态',
  UNIQUE KEY `uk_org_code` (`org_code`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='组织架构（院区 / 科室 / 用能部门）';

DROP TABLE IF EXISTS `sys_user`;
CREATE TABLE `sys_user` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(50) NOT NULL COMMENT '登录账号',
  `password` varchar(100) NOT NULL COMMENT 'BCrypt 密码',
  `real_name` varchar(50) NOT NULL COMMENT '姓名',
  `avatar` varchar(255) DEFAULT NULL COMMENT '头像相对路径',
  `role_code` varchar(30) NOT NULL COMMENT '角色编码',
  `org_id` bigint DEFAULT NULL COMMENT '所属组织',
  `phone` varchar(20) DEFAULT NULL COMMENT '手机',
  `email` varchar(100) DEFAULT NULL COMMENT '邮箱',
  `data_scope` varchar(10) NOT NULL DEFAULT 'SELF' COMMENT 'ALL / DEPT / SELF',
  `status` varchar(10) NOT NULL DEFAULT '启用' COMMENT '启用 / 停用',
  `login_fail` int DEFAULT 0 COMMENT '连续登录失败次数',
  `locked_until` datetime DEFAULT NULL COMMENT '锁定到期时间',
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_role` (`role_code`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户';

DROP TABLE IF EXISTS `sys_role`;
CREATE TABLE `sys_role` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `role_code` varchar(30) NOT NULL COMMENT '角色编码',
  `role_name` varchar(50) NOT NULL COMMENT '角色名称',
  `data_scope` varchar(10) NOT NULL COMMENT '数据范围',
  `remark` varchar(200) DEFAULT NULL COMMENT '说明',
  UNIQUE KEY `uk_role_code` (`role_code`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色';

DROP TABLE IF EXISTS `sys_menu`;
CREATE TABLE `sys_menu` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `parent_id` bigint DEFAULT 0 COMMENT '上级菜单',
  `menu_name` varchar(50) NOT NULL COMMENT '菜单名称',
  `path` varchar(100) DEFAULT NULL COMMENT '路由路径',
  `component` varchar(100) DEFAULT NULL COMMENT '前端组件',
  `icon` varchar(50) DEFAULT NULL COMMENT '图标',
  `perm` varchar(100) DEFAULT NULL COMMENT '权限标识',
  `menu_type` varchar(2) DEFAULT 'M' COMMENT 'M 目录 / C 菜单 / B 按钮',
  `sort` int DEFAULT 0 COMMENT '排序',
  `visible` tinyint DEFAULT 1 COMMENT '是否显示',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='菜单';

DROP TABLE IF EXISTS `sys_role_menu`;
CREATE TABLE `sys_role_menu` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `role_code` varchar(30) NOT NULL COMMENT '角色编码',
  `menu_id` bigint NOT NULL COMMENT '菜单ID',
  KEY `idx_role` (`role_code`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色菜单授权';

DROP TABLE IF EXISTS `sys_message`;
CREATE TABLE `sys_message` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `title` varchar(100) NOT NULL COMMENT '标题',
  `content` varchar(500) DEFAULT NULL COMMENT '内容',
  `biz_no` varchar(50) DEFAULT NULL COMMENT '业务编号',
  `biz_type` varchar(30) DEFAULT NULL COMMENT '业务类型',
  `receiver_id` bigint DEFAULT NULL COMMENT '接收人',
  `is_read` tinyint DEFAULT 0 COMMENT '是否已读',
  KEY `idx_receiver` (`receiver_id`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='站内消息';

DROP TABLE IF EXISTS `sys_log`;
CREATE TABLE `sys_log` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint DEFAULT NULL COMMENT '操作人ID',
  `username` varchar(50) DEFAULT NULL COMMENT '操作人账号',
  `module` varchar(50) DEFAULT NULL COMMENT '模块',
  `action` varchar(50) DEFAULT NULL COMMENT '动作',
  `method` varchar(150) DEFAULT NULL COMMENT '请求方法与路径',
  `params` varchar(500) DEFAULT NULL COMMENT '参数摘要',
  `ip` varchar(50) DEFAULT NULL COMMENT 'IP',
  `cost_ms` bigint DEFAULT 0 COMMENT '耗时毫秒',
  `result` varchar(20) DEFAULT 'OK' COMMENT '结果',
  KEY `idx_create` (`create_time`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作日志';

DROP TABLE IF EXISTS `sys_file`;
CREATE TABLE `sys_file` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `file_name` varchar(200) NOT NULL COMMENT '存储文件名',
  `original_name` varchar(255) DEFAULT NULL COMMENT '原始文件名',
  `file_path` varchar(255) NOT NULL COMMENT '相对路径',
  `file_size` bigint DEFAULT 0 COMMENT '字节数',
  `content_type` varchar(100) DEFAULT NULL COMMENT 'MIME',
  `uploader` varchar(50) DEFAULT NULL COMMENT '上传人',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文件元数据';

DROP TABLE IF EXISTS `building`;
CREATE TABLE `building` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `building_code` varchar(32) NOT NULL COMMENT '建筑编号',
  `building_name` varchar(100) NOT NULL COMMENT '建筑名称',
  `org_id` bigint DEFAULT NULL COMMENT '所属组织',
  `building_type` varchar(20) DEFAULT 'OFFICE' COMMENT 'SCHOOL/HOSPITAL/OFFICE/CULTURE',
  `address` varchar(200) DEFAULT NULL COMMENT '地址',
  `build_area` decimal(12,2) DEFAULT 0 COMMENT '建筑面积㎡',
  `floor_count` int DEFAULT 0 COMMENT '楼层数',
  `person_count` int DEFAULT 0 COMMENT '使用人数',
  `manager` varchar(50) DEFAULT NULL COMMENT '责任人',
  `status` varchar(10) DEFAULT '在用' COMMENT '状态',
  `cover_image` varchar(255) DEFAULT NULL COMMENT '建筑照片',
  UNIQUE KEY `uk_building_code` (`building_code`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='建筑';

DROP TABLE IF EXISTS `energy_unit`;
CREATE TABLE `energy_unit` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `unit_code` varchar(32) NOT NULL COMMENT '单元编码',
  `unit_name` varchar(100) NOT NULL COMMENT '单元名称',
  `building_id` bigint NOT NULL COMMENT '所属建筑',
  `floor_no` varchar(20) DEFAULT NULL COMMENT '楼层',
  `room_range` varchar(50) DEFAULT NULL COMMENT '房间范围',
  `area` decimal(10,2) DEFAULT 0 COMMENT '面积㎡',
  `person_count` int DEFAULT 0 COMMENT '人数',
  `manager_id` bigint DEFAULT NULL COMMENT '负责人',
  `status` varchar(10) DEFAULT '在用' COMMENT '状态',
  KEY `idx_building` (`building_id`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用能单元';

DROP TABLE IF EXISTS `meter`;
CREATE TABLE `meter` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `meter_code` varchar(50) NOT NULL COMMENT '表计编号',
  `meter_name` varchar(100) DEFAULT NULL COMMENT '表计名称',
  `energy_type` varchar(10) NOT NULL COMMENT 'ELEC/WATER/GAS/COOL',
  `building_id` bigint NOT NULL COMMENT '所属建筑',
  `unit_id` bigint DEFAULT NULL COMMENT '所属用能单元',
  `install_location` varchar(150) NOT NULL COMMENT '安装位置',
  `unit_name` varchar(20) NOT NULL COMMENT '计量单位',
  `ratio` decimal(8,2) NOT NULL DEFAULT 1 COMMENT '倍率',
  `last_reading` decimal(14,2) DEFAULT 0 COMMENT '上期读数',
  `status` varchar(10) DEFAULT '在用' COMMENT '在用/停用/待检定',
  `cycle_type` varchar(10) DEFAULT 'MONTH' COMMENT 'MONTH/QUARTER',
  `abnormal_flag` varchar(10) DEFAULT '正常' COMMENT '异常标记',
  `install_date` date DEFAULT NULL COMMENT '安装日期',
  UNIQUE KEY `uk_meter_code` (`meter_code`),
  KEY `idx_building` (`building_id`),
  KEY `idx_type` (`energy_type`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='能耗表计';

DROP TABLE IF EXISTS `reading_task`;
CREATE TABLE `reading_task` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `task_no` varchar(50) NOT NULL COMMENT '任务编号',
  `meter_id` bigint NOT NULL COMMENT '表计',
  `building_id` bigint NOT NULL COMMENT '建筑',
  `period` varchar(7) NOT NULL COMMENT '周期 yyyy-MM',
  `plan_date` date DEFAULT NULL COMMENT '计划日期',
  `deadline` date DEFAULT NULL COMMENT '截止日期',
  `reader_id` bigint DEFAULT NULL COMMENT '抄表员',
  `status` varchar(20) NOT NULL COMMENT 'GENERATED/READING/REVIEWING/EXCEPTION/ARCHIVED/REJECTED/MISSED',
  `source` varchar(20) DEFAULT 'PLAN' COMMENT 'PLAN/MANUAL/SUPPLEMENT',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  UNIQUE KEY `uk_task_no` (`task_no`),
  KEY `idx_meter_period` (`meter_id`, `period`),
  KEY `idx_status` (`status`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='抄表任务';

DROP TABLE IF EXISTS `meter_reading`;
CREATE TABLE `meter_reading` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `reading_no` varchar(50) NOT NULL COMMENT '记录编号',
  `task_id` bigint DEFAULT NULL COMMENT '任务',
  `meter_id` bigint NOT NULL COMMENT '表计',
  `period` varchar(7) NOT NULL COMMENT '周期',
  `prev_reading` decimal(14,2) NOT NULL COMMENT '上期读数',
  `curr_reading` decimal(14,2) NOT NULL COMMENT '本期读数',
  `usage_amount` decimal(14,2) NOT NULL COMMENT '本期用量',
  `read_time` datetime DEFAULT NULL COMMENT '抄表时间',
  `photo_path` varchar(255) NOT NULL COMMENT '表盘照片',
  `meter_status` varchar(10) DEFAULT '正常' COMMENT '表计状态',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `deviation_rate` decimal(8,2) DEFAULT 0 COMMENT '与历史均值偏差率%',
  `review_status` varchar(10) DEFAULT 'PENDING' COMMENT 'PENDING/PASS/REJECT',
  `reviewer_id` bigint DEFAULT NULL COMMENT '复核人',
  `review_time` datetime DEFAULT NULL COMMENT '复核时间',
  `review_note` varchar(255) DEFAULT NULL COMMENT '复核意见',
  `locked` tinyint DEFAULT 0 COMMENT '账单锁定标记',
  UNIQUE KEY `uk_reading_no` (`reading_no`),
  KEY `idx_meter_period` (`meter_id`, `period`),
  KEY `idx_period` (`period`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='抄表记录';

DROP TABLE IF EXISTS `tariff_rule`;
CREATE TABLE `tariff_rule` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `rule_name` varchar(100) NOT NULL COMMENT '规则名称',
  `energy_type` varchar(10) NOT NULL COMMENT '能源类型',
  `charge_type` varchar(10) NOT NULL DEFAULT 'FIXED' COMMENT 'FIXED/LADDER',
  `price` decimal(10,4) NOT NULL COMMENT '单价',
  `ladder_json` varchar(500) DEFAULT NULL COMMENT '阶梯配置',
  `effective_date` date NOT NULL COMMENT '生效日期',
  `version` varchar(20) NOT NULL COMMENT '版本号',
  `status` varchar(10) DEFAULT 'ENABLED' COMMENT 'ENABLED/DISABLED',
  KEY `idx_type` (`energy_type`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='计费规则';

DROP TABLE IF EXISTS `energy_bill`;
CREATE TABLE `energy_bill` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `bill_no` varchar(50) NOT NULL COMMENT '账单编号',
  `building_id` bigint NOT NULL COMMENT '建筑',
  `meter_id` bigint DEFAULT NULL COMMENT '表计',
  `energy_type` varchar(10) NOT NULL COMMENT '能源类型',
  `period` varchar(7) NOT NULL COMMENT '周期',
  `usage_amount` decimal(14,2) NOT NULL COMMENT '用量',
  `unit_price` decimal(10,4) NOT NULL COMMENT '单价',
  `amount` decimal(14,2) NOT NULL COMMENT '原始金额',
  `adjust_amount` decimal(14,2) DEFAULT 0 COMMENT '调整金额',
  `final_amount` decimal(14,2) NOT NULL COMMENT '结算金额',
  `status` varchar(10) DEFAULT '已确认' COMMENT '已确认/已锁定/待审批/已调整',
  `lock_flag` tinyint DEFAULT 1 COMMENT '是否锁定',
  `tariff_version` varchar(20) DEFAULT NULL COMMENT '计费规则版本',
  UNIQUE KEY `uk_bill_no` (`bill_no`),
  KEY `idx_period` (`period`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='费用台账';

DROP TABLE IF EXISTS `energy_exception`;
CREATE TABLE `energy_exception` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `exception_no` varchar(50) NOT NULL COMMENT '异常编号',
  `meter_id` bigint NOT NULL COMMENT '表计',
  `reading_id` bigint DEFAULT NULL COMMENT '抄表记录',
  `building_id` bigint NOT NULL COMMENT '建筑',
  `exception_type` varchar(20) NOT NULL COMMENT 'SURGE/DROP/FLAT/DAMAGE/CASCADE',
  `level` varchar(10) NOT NULL COMMENT 'HIGH/MID/LOW',
  `trigger_rule` varchar(500) DEFAULT NULL COMMENT '触发规则说明',
  `description` varchar(255) DEFAULT NULL COMMENT '异常描述',
  `handler_id` bigint DEFAULT NULL COMMENT '处理人',
  `status` varchar(20) DEFAULT 'OPEN' COMMENT 'OPEN/HANDLING/CLOSED/IGNORED',
  `cause` varchar(255) DEFAULT NULL COMMENT '原因',
  `handle_note` varchar(500) DEFAULT NULL COMMENT '处置说明',
  `close_time` datetime DEFAULT NULL COMMENT '关闭时间',
  UNIQUE KEY `uk_exception_no` (`exception_no`),
  KEY `idx_status` (`status`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='异常单';

DROP TABLE IF EXISTS `energy_quota`;
CREATE TABLE `energy_quota` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `quota_no` varchar(50) NOT NULL COMMENT '定额编号',
  `target_type` varchar(20) NOT NULL COMMENT 'BUILDING/DEPT',
  `target_id` bigint DEFAULT NULL COMMENT '对象ID',
  `target_name` varchar(100) NOT NULL COMMENT '对象名称',
  `energy_type` varchar(10) NOT NULL COMMENT '能源类型',
  `period_type` varchar(10) NOT NULL DEFAULT 'YEAR' COMMENT 'YEAR/MONTH',
  `quota_value` decimal(14,2) NOT NULL COMMENT '定额值',
  `used_value` decimal(14,2) DEFAULT 0 COMMENT '已用量',
  `year` int NOT NULL COMMENT '年度',
  UNIQUE KEY `uk_quota_no` (`quota_no`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='能耗定额';

DROP TABLE IF EXISTS `saving_measure`;
CREATE TABLE `saving_measure` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `measure_no` varchar(50) NOT NULL COMMENT '措施编号',
  `measure_name` varchar(150) NOT NULL COMMENT '措施名称',
  `building_id` bigint DEFAULT NULL COMMENT '建筑',
  `content` varchar(500) DEFAULT NULL COMMENT '措施内容',
  `invest_amount` decimal(10,2) DEFAULT 0 COMMENT '投入（万元）',
  `plan_start` date DEFAULT NULL COMMENT '计划开始',
  `plan_end` date DEFAULT NULL COMMENT '计划结束',
  `target_saving` decimal(10,2) DEFAULT 0 COMMENT '目标节能 tce',
  `actual_saving` decimal(10,2) DEFAULT NULL COMMENT '实际节能 tce',
  `status` varchar(10) DEFAULT '待启动' COMMENT '待启动/实施中/已验收',
  `owner_id` bigint DEFAULT NULL COMMENT '负责人',
  UNIQUE KEY `uk_measure_no` (`measure_no`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='节能措施';

DROP TABLE IF EXISTS `baseline_rule`;
CREATE TABLE `baseline_rule` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `rule_name` varchar(100) NOT NULL COMMENT '规则名称',
  `version` varchar(10) NOT NULL COMMENT '版本 v1/v2...',
  `weights_json` varchar(500) NOT NULL COMMENT '因子权重 JSON，合计 100',
  `threshold_json` varchar(200) DEFAULT NULL COMMENT '等级阈值',
  `status` varchar(10) NOT NULL DEFAULT 'ENABLED' COMMENT 'ENABLED/DISABLED',
  `effective_time` datetime DEFAULT NULL COMMENT '生效时间',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  UNIQUE KEY `uk_version` (`version`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='能耗基线识别规则';

DROP TABLE IF EXISTS `baseline_score`;
CREATE TABLE `baseline_score` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `score_no` varchar(50) NOT NULL COMMENT '计算编号',
  `building_id` bigint NOT NULL COMMENT '建筑',
  `meter_id` bigint DEFAULT NULL COMMENT '表计',
  `energy_type` varchar(10) DEFAULT NULL COMMENT '能源类型',
  `period` varchar(7) NOT NULL COMMENT '周期',
  `rule_id` bigint DEFAULT NULL COMMENT '规则ID',
  `rule_version` varchar(10) DEFAULT NULL COMMENT '规则版本',
  `input_json` text COMMENT '输入快照',
  `item_json` text COMMENT '因子明细',
  `total_score` decimal(5,1) NOT NULL COMMENT '总分',
  `level` varchar(10) NOT NULL COMMENT 'HIGH/MID/LOW',
  `conclusion` varchar(500) DEFAULT NULL COMMENT '结论',
  `main_factors` varchar(255) DEFAULT NULL COMMENT '主要影响因素',
  `unmet_json` text COMMENT '未满足条件',
  `improve_json` text COMMENT '可改进项',
  `adopt_flag` tinyint DEFAULT 0 COMMENT '是否采纳 0 待定 1 采纳',
  `adjust_level` varchar(10) DEFAULT NULL COMMENT '人工调整等级',
  `adjust_reason` varchar(255) DEFAULT NULL COMMENT '调整原因',
  `adjust_by` varchar(50) DEFAULT NULL COMMENT '调整人',
  `adjust_time` datetime DEFAULT NULL COMMENT '调整时间',
  `calc_time` datetime DEFAULT NULL COMMENT '计算时间',
  UNIQUE KEY `uk_score_no` (`score_no`),
  KEY `idx_level` (`level`),
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 1 删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='基线识别计算留痕';

INSERT INTO `sys_org` (`org_code`, `org_name`, `parent_id`, `org_type`, `leader`, `phone`, `sort`, `status`) VALUES
('ORG-001', '市机关事务管理局', 0, 'CAMPUS', '张立', '0571-88010001', 1, '启用'),
('ORG-002', '后勤保障处', 1, 'DEPT', '王建国', '0571-88010002', 2, '启用'),
('ORG-003', '节能管理科', 1, 'DEPT', '张立', '0571-88010003', 3, '启用'),
('ORG-004', '第一人民医院总务处', 1, 'DEPT', '李海燕', '0571-88010004', 4, '启用'),
('ORG-005', '实验中学总务处', 1, 'DEPT', '陈勇', '0571-88010005', 5, '启用'),
('ORG-006', '政务服务中心办公室', 1, 'DEPT', '周敏', '0571-88010006', 6, '启用');

INSERT INTO `sys_role` (`role_code`, `role_name`, `data_scope`, `remark`) VALUES
('ADMIN', '系统管理员', 'ALL', '用户、组织、角色、计费规则与日志'),
('ENERGY_ADMIN', '能源管理员', 'ALL', '维护台账、校验数据、设定定额、处理异常与报表'),
('READER', '抄表员', 'SELF', '执行水、电、燃气和冷热量抄表任务'),
('LIAISON', '用能部门联络员', 'DEPT', '查看本部门能耗、填写异常说明、提交节能措施');

INSERT INTO `sys_user` (`username`, `password`, `real_name`, `avatar`, `role_code`, `org_id`, `phone`, `email`, `data_scope`, `status`, `login_fail`, `locked_until`, `create_time`) VALUES
('admin', '$2b$10$d7M9mJViBIo0up586z48Ke5LZMzXoKZ4fkEwr5xZFx9YN3VwOwNe6', '系统管理员', '/uploads/seed/avatar/01.jpg', 'ADMIN', 1, '13800000001', 'admin@energy.gov.cn', 'ALL', '启用', 0, NULL, '2026-01-05 09:00:00'),
('zhangli', '$2b$10$FiwCmTi8VOgE.gxxod2jf.UdwDFN66xzNJ8gPXzXM4hzehMbx4Jve', '张立', '/uploads/seed/avatar/02.jpg', 'ENERGY_ADMIN', 3, '13800000002', 'zhangli@energy.gov.cn', 'ALL', '启用', 0, NULL, '2026-01-08 09:20:00'),
('wangjg', '$2b$10$FiwCmTi8VOgE.gxxod2jf.UdwDFN66xzNJ8gPXzXM4hzehMbx4Jve', '王建国', '/uploads/seed/avatar/03.jpg', 'READER', 2, '13800000003', NULL, 'SELF', '启用', 0, NULL, '2026-02-11 10:05:00'),
('lihy', '$2b$10$FiwCmTi8VOgE.gxxod2jf.UdwDFN66xzNJ8gPXzXM4hzehMbx4Jve', '李海燕', '/uploads/seed/avatar/04.jpg', 'READER', 4, '13800000004', NULL, 'SELF', '启用', 0, NULL, '2026-02-11 10:06:00'),
('zhaom', '$2b$10$FiwCmTi8VOgE.gxxod2jf.UdwDFN66xzNJ8gPXzXM4hzehMbx4Jve', '赵明', '/uploads/seed/avatar/05.jpg', 'READER', 5, '13800000005', NULL, 'SELF', '停用', 0, NULL, '2026-03-02 14:30:00'),
('cheny', '$2b$10$FiwCmTi8VOgE.gxxod2jf.UdwDFN66xzNJ8gPXzXM4hzehMbx4Jve', '陈勇', '/uploads/seed/avatar/06.jpg', 'LIAISON', 5, '13800000006', 'cheny@school.edu.cn', 'DEPT', '启用', 0, NULL, '2026-03-02 14:35:00'),
('zhoum', '$2b$10$FiwCmTi8VOgE.gxxod2jf.UdwDFN66xzNJ8gPXzXM4hzehMbx4Jve', '周敏', '/uploads/seed/avatar/07.jpg', 'LIAISON', 6, '13800000007', NULL, 'DEPT', '启用', 0, NULL, '2026-04-06 09:12:00'),
('sunyf', '$2b$10$FiwCmTi8VOgE.gxxod2jf.UdwDFN66xzNJ8gPXzXM4hzehMbx4Jve', '孙一凡', '/uploads/seed/avatar/08.jpg', 'READER', 2, '13800000008', NULL, 'SELF', '启用', 0, NULL, '2026-04-18 15:40:00');

INSERT INTO `sys_menu` (`parent_id`, `menu_name`, `path`, `component`, `icon`, `perm`, `menu_type`, `sort`, `visible`, `create_time`) VALUES
(0, '能耗监测', '/monitor', NULL, 'dashboard', NULL, 'M', 1, 1, '2026-01-05 09:00:00'),
(1, '节能分析看板', '/dashboard', 'Dashboard', 'dashboard', 'dashboard:view', 'C', 2, 1, '2026-01-05 09:00:00'),
(1, '建筑与用能单元', '/building', 'Building', 'building', 'building:view', 'C', 3, 1, '2026-01-05 09:00:00'),
(1, '表计资产台账', '/meter', 'Meter', 'meter', 'meter:view', 'C', 4, 1, '2026-01-05 09:00:00'),
(0, '抄表作业', '/reading', NULL, 'task', NULL, 'M', 5, 1, '2026-01-05 09:00:00'),
(5, '抄表任务', '/task', 'Task', 'task', 'task:view', 'C', 6, 1, '2026-01-05 09:00:00'),
(5, '抄表记录', '/record', 'Reading', 'reading', 'reading:view', 'C', 7, 1, '2026-01-05 09:00:00'),
(5, '异常复核中心', '/exception', 'Exception', 'warning', 'exception:view', 'C', 8, 1, '2026-01-05 09:00:00'),
(0, '费用与定额', '/cost', NULL, 'bill', NULL, 'M', 9, 1, '2026-01-05 09:00:00'),
(9, '费用台账', '/bill', 'Bill', 'bill', 'bill:view', 'C', 10, 1, '2026-01-05 09:00:00'),
(9, '能耗定额', '/quota', 'Quota', 'quota', 'quota:view', 'C', 11, 1, '2026-01-05 09:00:00'),
(0, '节能管理', '/saving', NULL, 'leaf', NULL, 'M', 12, 1, '2026-01-05 09:00:00'),
(12, '能耗基线识别', '/baseline', 'Baseline', 'rule', 'baseline:view', 'C', 13, 1, '2026-01-05 09:00:00'),
(12, '节能措施', '/measure', 'Measure', 'leaf', 'measure:view', 'C', 14, 1, '2026-01-05 09:00:00'),
(0, '系统', '/system', NULL, 'system', NULL, 'M', 15, 1, '2026-01-05 09:00:00'),
(15, '用户与角色', '/system/user', 'System', 'user', 'system:user', 'C', 16, 1, '2026-01-05 09:00:00'),
(15, '菜单管理', '/system/menu', 'System', 'system', 'system:menu', 'C', 17, 1, '2026-01-05 09:00:00'),
(15, '操作日志', '/system/log', 'System', 'clock', 'system:log', 'C', 18, 1, '2026-01-05 09:00:00'),
(0, '个人中心', '/profile', NULL, 'user', NULL, 'M', 19, 1, '2026-01-05 09:00:00'),
(19, '个人资料', '/profile', 'Profile', 'user', 'profile:view', 'C', 20, 1, '2026-01-05 09:00:00');

INSERT INTO `sys_role_menu` (`role_code`, `menu_id`) VALUES
('ADMIN', 1),
('ADMIN', 2),
('ADMIN', 3),
('ADMIN', 4),
('ADMIN', 5),
('ADMIN', 6),
('ADMIN', 7),
('ADMIN', 8),
('ADMIN', 9),
('ADMIN', 10),
('ADMIN', 11),
('ADMIN', 12),
('ADMIN', 13),
('ADMIN', 14),
('ADMIN', 15),
('ADMIN', 16),
('ADMIN', 17),
('ADMIN', 18),
('ADMIN', 19),
('ADMIN', 20),
('ENERGY_ADMIN', 1),
('ENERGY_ADMIN', 2),
('ENERGY_ADMIN', 3),
('ENERGY_ADMIN', 4),
('ENERGY_ADMIN', 5),
('ENERGY_ADMIN', 6),
('ENERGY_ADMIN', 7),
('ENERGY_ADMIN', 8),
('ENERGY_ADMIN', 9),
('ENERGY_ADMIN', 10),
('ENERGY_ADMIN', 11),
('ENERGY_ADMIN', 12),
('ENERGY_ADMIN', 13),
('ENERGY_ADMIN', 14),
('ENERGY_ADMIN', 19),
('ENERGY_ADMIN', 20),
('READER', 5),
('READER', 6),
('READER', 7),
('READER', 8),
('READER', 19),
('READER', 20),
('LIAISON', 1),
('LIAISON', 2),
('LIAISON', 4),
('LIAISON', 6),
('LIAISON', 7),
('LIAISON', 12),
('LIAISON', 14),
('LIAISON', 19),
('LIAISON', 20);

INSERT INTO `building` (`building_code`, `building_name`, `org_id`, `building_type`, `address`, `build_area`, `floor_count`, `person_count`, `manager`, `status`, `cover_image`) VALUES
('BD-001', '行政中心A座', 1, 'OFFICE', '解放路 18 号', 24800.0, 12, 860, '王建国', '在用', '/uploads/seed/building/01.jpg'),
('BD-002', '第一人民医院门诊楼', 4, 'HOSPITAL', '健康路 66 号', 36800.0, 8, 3200, '李海燕', '在用', '/uploads/seed/building/02.jpg'),
('BD-003', '实验中学教学楼', 5, 'SCHOOL', '文教路 9 号', 12400.0, 5, 1860, '陈勇', '在用', '/uploads/seed/building/03.jpg'),
('BD-004', '政务服务中心', 6, 'OFFICE', '市民大道 1 号', 18600.0, 6, 1200, '周敏', '在用', '/uploads/seed/building/04.jpg'),
('BD-005', '图书馆', 1, 'CULTURE', '文化路 22 号', 9200.0, 4, 460, '孙一凡', '在用', '/uploads/seed/building/05.jpg'),
('BD-006', '疾控中心实验楼', 1, 'OFFICE', '卫生路 8 号', 7600.0, 5, 320, '张立', '在用', '/uploads/seed/building/06.jpg'),
('BD-007', '第一人民医院住院楼', 4, 'HOSPITAL', '健康路 66 号', 28400.0, 15, 2400, '李海燕', '在用', '/uploads/seed/building/02.jpg'),
('BD-008', '实验中学体育馆', 5, 'SCHOOL', '文教路 9 号', 5600.0, 2, 900, '陈勇', '在用', '/uploads/seed/building/03.jpg');

INSERT INTO `energy_unit` (`unit_code`, `unit_name`, `building_id`, `floor_no`, `room_range`, `area`, `person_count`, `manager_id`, `status`) VALUES
('U-001', '后勤保障处', 1, '1-3F', '101-320', 4200.0, 120, 2, '在用'),
('U-002', '节能管理科', 1, '4F', '401-418', 860.0, 26, 2, '在用'),
('U-003', '门诊科室', 2, '1-4F', '101-430', 12800.0, 1400, 4, '在用'),
('U-004', '住院病区', 7, '3-15F', '301-1520', 18600.0, 2200, 4, '在用'),
('U-005', '教学楼A区', 3, '1-5F', '101-520', 6400.0, 1100, 5, '在用'),
('U-006', '教学楼B区', 3, '1-4F', '101-418', 4200.0, 760, 5, '在用'),
('U-007', '政务服务大厅', 4, '1-2F', '101-210', 6800.0, 680, 6, '在用'),
('U-008', '图书阅览区', 5, '1-4F', '101-408', 6400.0, 460, 8, '在用'),
('U-009', '实验区', 6, '1-5F', '101-508', 5200.0, 320, 2, '在用'),
('U-010', '体育馆场馆区', 8, '1-2F', '101-205', 4800.0, 900, 5, '在用');

INSERT INTO `meter` (`meter_code`, `meter_name`, `energy_type`, `building_id`, `unit_id`, `install_location`, `unit_name`, `ratio`, `last_reading`, `status`, `cycle_type`, `abnormal_flag`, `install_date`, `update_time`) VALUES
('EM-D-0101', 'D-0101 表计', 'ELEC', 1, 1, 'B1 配电房 3#柜', 'kWh', 80, 1284320.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-05-10 09:00:00'),
('EM-D-0102', 'D-0102 表计', 'ELEC', 1, 2, '5F 照明总箱', 'kWh', 40, 462180.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-06-11 09:01:00'),
('EM-D-0103', 'D-0103 表计', 'ELEC', 1, 1, 'B1 空调配电柜', 'kWh', 60, 786540.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-07-12 09:02:00'),
('EM-W-0104', 'W-0104 表计', 'WATER', 1, 1, '1F 水表井', 'm³', 1, 42860.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-08-13 09:03:00'),
('EM-D-0201', 'D-0201 表计', 'ELEC', 2, 3, 'B1 配电房 1#柜', 'kWh', 100, 962400.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-09-14 09:04:00'),
('EM-D-0202', 'D-0202 表计', 'ELEC', 2, 3, '3F 空调机房', 'kWh', 60, 534200.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-010-15 09:05:00'),
('EM-W-0203', 'W-0203 表计', 'WATER', 2, 3, '1F 水表井', 'm³', 1, 86412.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-05-16 09:06:00'),
('EM-G-0204', 'G-0204 表计', 'GAS', 2, 3, '食堂燃气间', 'm³', 1, 42905.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-06-17 09:07:00'),
('EM-D-0205', 'D-0205 表计', 'ELEC', 7, 4, 'B1 配电房 2#柜', 'kWh', 120, 1187640.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-07-18 09:08:00'),
('EM-C-0206', 'C-0206 表计', 'COOL', 7, 4, '冷站 1# 总管', 'GJ', 1, 12486.0, '待检定', 'QUARTER', '正常', '2023-06-01', '2026-08-10 09:09:00'),
('EM-D-0301', 'D-0301 表计', 'ELEC', 3, 5, '1F 配电间总柜', 'kWh', 60, 318760.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-09-11 09:10:00'),
('EM-D-0302', 'D-0302 表计', 'ELEC', 3, 5, '2F 照明箱', 'kWh', 30, 96420.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-010-12 09:11:00'),
('EM-D-0303', 'D-0303 表计', 'ELEC', 3, 6, '3F 插座箱', 'kWh', 30, 42860.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-05-13 09:12:00'),
('EM-W-0304', 'W-0304 表计', 'WATER', 3, 5, '1F 水表井', 'm³', 1, 18420.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-06-14 09:13:00'),
('EM-D-0401', 'D-0401 表计', 'ELEC', 4, 7, 'B1 配电房', 'kWh', 80, 421800.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-07-15 09:14:00'),
('EM-G-0402', 'G-0402 表计', 'GAS', 4, 7, '食堂燃气间', 'm³', 1, 15840.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-08-16 09:15:00'),
('EM-C-0403', 'C-0403 表计', 'COOL', 4, 7, '冷站 1# 总管', 'GJ', 1, 8620.0, '停用', 'QUARTER', '正常', '2023-06-01', '2026-09-17 09:16:00'),
('EM-W-0501', 'W-0501 表计', 'WATER', 5, 8, '卫生间主管', 'm³', 1, 6742.0, '待检定', 'MONTH', '正常', '2023-06-01', '2026-010-18 09:17:00'),
('EM-D-0502', 'D-0502 表计', 'ELEC', 5, 8, '1F 配电间', 'kWh', 40, 186420.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-05-10 09:18:00'),
('EM-D-0601', 'D-0601 表计', 'ELEC', 6, 9, 'B1 配电房', 'kWh', 60, 246800.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-06-11 09:19:00'),
('EM-D-0602', 'D-0602 表计', 'ELEC', 6, 9, '4F 实验区配电箱', 'kWh', 30, 128460.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-07-12 09:20:00'),
('EM-D-0801', 'D-0801 表计', 'ELEC', 8, 10, '1F 场馆配电箱', 'kWh', 30, 86420.0, '在用', 'MONTH', '正常', '2023-06-01', '2026-08-13 09:21:00');

INSERT INTO `tariff_rule` (`rule_name`, `energy_type`, `charge_type`, `price`, `ladder_json`, `effective_date`, `version`, `status`) VALUES
('居民与机关用电（阶梯）', 'ELEC', 'LADDER', 0.68, '{"t1":10000,"p1":0.65,"p2":0.68,"p3":0.72}', '2026-01-01', 'v2026.01', 'DISABLED'),
('机关事业单位用电', 'ELEC', 'LADDER', 0.7, '{"t1":20000,"p1":0.68,"p2":0.70,"p3":0.74}', '2026-04-01', 'v2026.04', 'DISABLED'),
('机关事业单位用电（现行）', 'ELEC', 'LADDER', 0.71, '{"t1":20000,"p1":0.68,"p2":0.71,"p3":0.75}', '2026-07-01', 'v2026.10', 'ENABLED'),
('公共机构用水', 'WATER', 'FIXED', 3.45, NULL, '2026-01-01', 'v2026.01', 'ENABLED'),
('公共机构管道燃气', 'GAS', 'FIXED', 3.1, NULL, '2026-04-01', 'v2026.04', 'ENABLED'),
('冷热量计量', 'COOL', 'FIXED', 42.0, NULL, '2026-06-01', 'v2026.06', 'ENABLED');

-- 数据自检：表计 22 台，规则 6 条

INSERT INTO `reading_task` (`task_no`, `meter_id`, `building_id`, `period`, `plan_date`, `deadline`, `reader_id`, `status`, `source`, `remark`, `create_time`) VALUES
('TK-202605-001', 1, 1, '2026-05', '2026-05-25', '2026-05-24', 3, 'ARCHIVED', 'PLAN', NULL, '2026-05-20 08:00:00'),
('TK-202605-002', 2, 1, '2026-05', '2026-05-25', '2026-05-25', 4, 'ARCHIVED', 'PLAN', NULL, '2026-05-21 08:01:00'),
('TK-202605-003', 3, 2, '2026-05', '2026-05-25', '2026-05-26', 5, 'ARCHIVED', 'PLAN', NULL, '2026-05-22 08:02:00'),
('TK-202605-004', 4, 2, '2026-05', '2026-05-25', '2026-05-27', 8, 'ARCHIVED', 'PLAN', NULL, '2026-05-23 08:03:00'),
('TK-202605-005', 5, 7, '2026-05', '2026-05-25', '2026-05-28', 3, 'ARCHIVED', 'PLAN', NULL, '2026-05-24 08:04:00'),
('TK-202605-006', 6, 3, '2026-05', '2026-05-25', '2026-05-24', 4, 'ARCHIVED', 'PLAN', NULL, '2026-05-20 08:05:00'),
('TK-202605-007', 7, 3, '2026-05', '2026-05-25', '2026-05-25', 5, 'ARCHIVED', 'PLAN', NULL, '2026-05-21 08:06:00'),
('TK-202605-008', 8, 4, '2026-05', '2026-05-25', '2026-05-26', 8, 'ARCHIVED', 'PLAN', NULL, '2026-05-22 08:07:00'),
('TK-202605-009', 9, 4, '2026-05', '2026-05-25', '2026-05-27', 3, 'ARCHIVED', 'PLAN', NULL, '2026-05-23 08:08:00'),
('TK-202605-010', 10, 5, '2026-05', '2026-05-25', '2026-05-28', 4, 'ARCHIVED', 'PLAN', NULL, '2026-05-24 08:09:00'),
('TK-202606-011', 1, 1, '2026-06', '2026-06-25', '2026-06-24', 3, 'ARCHIVED', 'PLAN', NULL, '2026-06-20 08:00:00'),
('TK-202606-012', 2, 1, '2026-06', '2026-06-25', '2026-06-25', 4, 'ARCHIVED', 'PLAN', NULL, '2026-06-21 08:01:00'),
('TK-202606-013', 3, 2, '2026-06', '2026-06-25', '2026-06-26', 5, 'ARCHIVED', 'PLAN', NULL, '2026-06-22 08:02:00'),
('TK-202606-014', 4, 2, '2026-06', '2026-06-25', '2026-06-27', 8, 'ARCHIVED', 'PLAN', NULL, '2026-06-23 08:03:00'),
('TK-202606-015', 5, 7, '2026-06', '2026-06-25', '2026-06-28', 3, 'ARCHIVED', 'PLAN', NULL, '2026-06-24 08:04:00'),
('TK-202606-016', 6, 3, '2026-06', '2026-06-25', '2026-06-24', 4, 'ARCHIVED', 'PLAN', NULL, '2026-06-20 08:05:00'),
('TK-202606-017', 7, 3, '2026-06', '2026-06-25', '2026-06-25', 5, 'ARCHIVED', 'PLAN', NULL, '2026-06-21 08:06:00'),
('TK-202606-018', 8, 4, '2026-06', '2026-06-25', '2026-06-26', 8, 'ARCHIVED', 'PLAN', NULL, '2026-06-22 08:07:00'),
('TK-202606-019', 9, 5, '2026-06', '2026-06-25', '2026-06-27', 3, 'ARCHIVED', 'PLAN', NULL, '2026-06-23 08:08:00'),
('TK-202606-020', 10, 6, '2026-06', '2026-06-25', '2026-06-28', 4, 'ARCHIVED', 'PLAN', NULL, '2026-06-24 08:09:00'),
('TK-202607-021', 1, 1, '2026-07', '2026-07-25', '2026-07-24', 3, 'ARCHIVED', 'PLAN', NULL, '2026-07-20 08:00:00'),
('TK-202607-022', 2, 2, '2026-07', '2026-07-25', '2026-07-25', 4, 'ARCHIVED', 'PLAN', NULL, '2026-07-21 08:01:00'),
('TK-202607-023', 3, 2, '2026-07', '2026-07-25', '2026-07-26', 5, 'ARCHIVED', 'PLAN', NULL, '2026-07-22 08:02:00'),
('TK-202607-024', 4, 7, '2026-07', '2026-07-25', '2026-07-27', 8, 'ARCHIVED', 'PLAN', NULL, '2026-07-23 08:03:00'),
('TK-202607-025', 5, 3, '2026-07', '2026-07-25', '2026-07-28', 3, 'ARCHIVED', 'PLAN', NULL, '2026-07-24 08:04:00'),
('TK-202607-026', 6, 3, '2026-07', '2026-07-25', '2026-07-24', 4, 'ARCHIVED', 'PLAN', NULL, '2026-07-20 08:05:00'),
('TK-202607-027', 7, 4, '2026-07', '2026-07-25', '2026-07-25', 5, 'ARCHIVED', 'PLAN', NULL, '2026-07-21 08:06:00'),
('TK-202607-028', 8, 4, '2026-07', '2026-07-25', '2026-07-26', 8, 'ARCHIVED', 'PLAN', NULL, '2026-07-22 08:07:00'),
('TK-202607-029', 9, 5, '2026-07', '2026-07-25', '2026-07-27', 3, 'ARCHIVED', 'PLAN', NULL, '2026-07-23 08:08:00'),
('TK-202607-030', 10, 6, '2026-07', '2026-07-25', '2026-07-28', 4, 'ARCHIVED', 'PLAN', NULL, '2026-07-24 08:09:00'),
('TK-202608-031', 1, 1, '2026-08', '2026-08-25', '2026-08-24', 3, 'ARCHIVED', 'PLAN', NULL, '2026-08-20 08:00:00'),
('TK-202608-032', 2, 2, '2026-08', '2026-08-25', '2026-08-25', 4, 'ARCHIVED', 'PLAN', NULL, '2026-08-21 08:01:00'),
('TK-202608-033', 3, 2, '2026-08', '2026-08-25', '2026-08-26', 5, 'ARCHIVED', 'PLAN', NULL, '2026-08-22 08:02:00'),
('TK-202608-034', 4, 7, '2026-08', '2026-08-25', '2026-08-27', 8, 'ARCHIVED', 'PLAN', NULL, '2026-08-23 08:03:00'),
('TK-202608-035', 5, 3, '2026-08', '2026-08-25', '2026-08-28', 3, 'ARCHIVED', 'PLAN', NULL, '2026-08-24 08:04:00'),
('TK-202608-036', 6, 3, '2026-08', '2026-08-25', '2026-08-24', 4, 'ARCHIVED', 'PLAN', NULL, '2026-08-20 08:05:00'),
('TK-202608-037', 7, 4, '2026-08', '2026-08-25', '2026-08-25', 5, 'ARCHIVED', 'PLAN', NULL, '2026-08-21 08:06:00'),
('TK-202608-038', 8, 5, '2026-08', '2026-08-25', '2026-08-26', 8, 'ARCHIVED', 'PLAN', NULL, '2026-08-22 08:07:00'),
('TK-202608-039', 9, 6, '2026-08', '2026-08-25', '2026-08-27', 3, 'ARCHIVED', 'PLAN', NULL, '2026-08-23 08:08:00'),
('TK-202608-040', 10, 8, '2026-08', '2026-08-25', '2026-08-28', 4, 'ARCHIVED', 'PLAN', NULL, '2026-08-24 08:09:00'),
('TK-202609-041', 1, 2, '2026-09', '2026-09-25', '2026-09-24', 3, 'ARCHIVED', 'PLAN', NULL, '2026-09-20 08:00:00'),
('TK-202609-042', 2, 2, '2026-09', '2026-09-25', '2026-09-25', 4, 'ARCHIVED', 'PLAN', NULL, '2026-09-21 08:01:00'),
('TK-202609-043', 3, 7, '2026-09', '2026-09-25', '2026-09-26', 5, 'REVIEWING', 'PLAN', NULL, '2026-09-22 08:02:00'),
('TK-202609-044', 4, 3, '2026-09', '2026-09-25', '2026-09-27', 8, 'EXCEPTION', 'PLAN', NULL, '2026-09-23 08:03:00'),
('TK-202609-045', 5, 3, '2026-09', '2026-09-25', '2026-09-28', 3, 'REJECTED', 'PLAN', NULL, '2026-09-24 08:04:00'),
('TK-202609-046', 6, 4, '2026-09', '2026-09-25', '2026-09-24', 4, 'MISSED', 'PLAN', NULL, '2026-09-20 08:05:00'),
('TK-202609-047', 7, 4, '2026-09', '2026-09-25', '2026-09-25', 5, 'ARCHIVED', 'PLAN', NULL, '2026-09-21 08:06:00'),
('TK-202609-048', 8, 5, '2026-09', '2026-09-25', '2026-09-26', 8, 'ARCHIVED', 'PLAN', NULL, '2026-09-22 08:07:00'),
('TK-202609-049', 9, 6, '2026-09', '2026-09-25', '2026-09-27', 3, 'REVIEWING', 'PLAN', NULL, '2026-09-23 08:08:00'),
('TK-202610-050', 1, 1, '2026-10', '2026-10-25', '2026-10-24', 3, 'GENERATED', 'PLAN', NULL, '2026-10-20 08:00:00'),
('TK-202610-051', 2, 1, '2026-10', '2026-10-25', '2026-10-25', 4, 'READING', 'PLAN', NULL, '2026-10-21 08:01:00'),
('TK-202610-052', 3, 1, '2026-10', '2026-10-25', '2026-10-26', 5, 'REVIEWING', 'PLAN', NULL, '2026-10-22 08:02:00'),
('TK-202610-053', 4, 1, '2026-10', '2026-10-25', '2026-10-27', 8, 'EXCEPTION', 'PLAN', NULL, '2026-10-23 08:03:00'),
('TK-202610-054', 5, 2, '2026-10', '2026-10-25', '2026-10-28', 3, 'ARCHIVED', 'PLAN', NULL, '2026-10-24 08:04:00'),
('TK-202610-055', 6, 2, '2026-10', '2026-10-25', '2026-10-24', 4, 'ARCHIVED', 'PLAN', NULL, '2026-10-20 08:05:00'),
('TK-202610-056', 7, 2, '2026-10', '2026-10-25', '2026-10-25', 5, 'REJECTED', 'PLAN', NULL, '2026-10-21 08:06:00'),
('TK-202610-057', 8, 2, '2026-10', '2026-10-25', '2026-10-26', 8, 'MISSED', 'PLAN', NULL, '2026-10-22 08:07:00'),
('TK-202610-058', 9, 7, '2026-10', '2026-10-25', '2026-10-27', 3, 'REVIEWING', 'PLAN', NULL, '2026-10-23 08:08:00'),
('TK-202610-059', 10, 7, '2026-10', '2026-10-25', '2026-10-28', 4, 'GENERATED', 'PLAN', NULL, '2026-10-24 08:09:00'),
('TK-202610-060', 11, 3, '2026-10', '2026-10-25', '2026-10-24', 5, 'GENERATED', 'PLAN', NULL, '2026-10-20 08:10:00'),
('TK-202610-061', 12, 3, '2026-10', '2026-10-25', '2026-10-25', 8, 'READING', 'PLAN', NULL, '2026-10-21 08:11:00'),
('TK-202610-062', 13, 3, '2026-10', '2026-10-25', '2026-10-26', 3, 'REVIEWING', 'PLAN', NULL, '2026-10-22 08:12:00'),
('TK-202610-063', 14, 3, '2026-10', '2026-10-25', '2026-10-27', 4, 'EXCEPTION', 'PLAN', NULL, '2026-10-23 08:13:00'),
('TK-202610-064', 15, 4, '2026-10', '2026-10-25', '2026-10-28', 5, 'ARCHIVED', 'PLAN', NULL, '2026-10-24 08:14:00'),
('TK-202610-065', 16, 4, '2026-10', '2026-10-25', '2026-10-24', 8, 'ARCHIVED', 'PLAN', NULL, '2026-10-20 08:15:00'),
('TK-202610-066', 17, 4, '2026-10', '2026-10-25', '2026-10-25', 3, 'REJECTED', 'PLAN', NULL, '2026-10-21 08:16:00'),
('TK-202610-067', 18, 5, '2026-10', '2026-10-25', '2026-10-26', 4, 'MISSED', 'PLAN', NULL, '2026-10-22 08:17:00'),
('TK-202610-068', 19, 5, '2026-10', '2026-10-25', '2026-10-27', 5, 'REVIEWING', 'PLAN', NULL, '2026-10-23 08:18:00'),
('TK-202610-069', 20, 6, '2026-10', '2026-10-25', '2026-10-28', 8, 'GENERATED', 'PLAN', NULL, '2026-10-24 08:19:00'),
('TK-202610-070', 21, 6, '2026-10', '2026-10-25', '2026-10-24', 3, 'GENERATED', 'PLAN', NULL, '2026-10-20 08:20:00'),
('TK-202610-071', 22, 8, '2026-10', '2026-10-25', '2026-10-25', 4, 'READING', 'PLAN', NULL, '2026-10-21 08:21:00');

INSERT INTO `meter_reading` (`reading_no`, `task_id`, `meter_id`, `period`, `prev_reading`, `curr_reading`, `usage_amount`, `read_time`, `photo_path`, `meter_status`, `remark`, `deviation_rate`, `review_status`, `reviewer_id`, `review_time`, `review_note`, `locked`, `create_time`) VALUES
('RD-202605-001', 1, 1, '2026-05', '1270903.87', '1284320.00', '13416.13', '2026-05-24 09:00:00', '/uploads/seed/meter/01.jpg', '正常', NULL, '4.22', 'PASS', 2, '2026-05-24 16:00:00', '数据核对无误', 1, '2026-05-20 09:00:00'),
('RD-202605-002', 2, 2, '2026-05', '777883.96', '786540.00', '8656.04', '2026-05-25 10:02:00', '/uploads/seed/meter/02.jpg', '正常', NULL, '0.20', 'PASS', 2, '2026-05-25 16:00:00', '数据核对无误', 1, '2026-05-21 09:01:00'),
('RD-202605-003', 3, 3, '2026-05', '953093.68', '962400.00', '9306.32', '2026-05-26 11:04:00', '/uploads/seed/meter/03.jpg', '正常', NULL, '-0.39', 'PASS', 2, '2026-05-26 16:00:00', '数据核对无误', 1, '2026-05-22 09:02:00'),
('RD-202605-004', 4, 4, '2026-05', '85284.28', '86412.00', '1127.72', '2026-05-27 12:06:00', '/uploads/seed/meter/04.jpg', '正常', NULL, '-6.27', 'PASS', 2, '2026-05-27 16:00:00', '数据核对无误', 1, '2026-05-23 09:03:00'),
('RD-202605-005', 5, 5, '2026-05', '1170749.64', '1187640.00', '16890.36', '2026-05-28 13:08:00', '/uploads/seed/meter/05.jpg', '正常', NULL, '5.96', 'PASS', 2, '2026-05-28 16:00:00', '数据核对无误', 1, '2026-05-24 09:04:00'),
('RD-202605-006', 6, 6, '2026-05', '314261.61', '318760.00', '4498.39', '2026-05-24 14:10:00', '/uploads/seed/meter/06.jpg', '正常', NULL, '1.39', 'PASS', 2, '2026-05-24 16:00:00', '数据核对无误', 1, '2026-05-20 09:05:00'),
('RD-202605-007', 7, 7, '2026-05', '42424.36', '42860.00', '435.64', '2026-05-25 15:12:00', '/uploads/seed/meter/07.jpg', '正常', NULL, '-6.73', 'PASS', 2, '2026-05-25 16:00:00', '数据核对无误', 1, '2026-05-21 09:06:00'),
('RD-202605-008', 8, 8, '2026-05', '416524.93', '421800.00', '5275.07', '2026-05-26 16:14:00', '/uploads/seed/meter/08.jpg', '正常', NULL, '-5.08', 'PASS', 2, '2026-05-26 16:00:00', '数据核对无误', 1, '2026-05-22 09:07:00'),
('RD-202605-009', 9, 9, '2026-05', '8484.83', '8620.00', '135.17', '2026-05-27 09:16:00', '/uploads/seed/meter/01.jpg', '正常', NULL, '5.97', 'PASS', 2, '2026-05-27 16:00:00', '数据核对无误', 1, '2026-05-23 09:08:00'),
('RD-202605-010', 10, 10, '2026-05', '184392.27', '186420.00', '2027.73', '2026-05-28 10:18:00', '/uploads/seed/meter/02.jpg', '正常', NULL, '1.82', 'PASS', 2, '2026-05-28 16:00:00', '数据核对无误', 1, '2026-05-24 09:09:00'),
('RD-202606-011', 11, 1, '2026-06', '458090.44', '462180.00', '4089.56', '2026-06-24 09:00:00', '/uploads/seed/meter/01.jpg', '正常', NULL, '-1.22', 'PASS', 2, '2026-06-24 16:00:00', '数据核对无误', 1, '2026-06-20 09:00:00'),
('RD-202606-012', 12, 2, '2026-06', '42300.16', '42860.00', '559.84', '2026-06-25 10:02:00', '/uploads/seed/meter/02.jpg', '正常', NULL, '-0.17', 'PASS', 2, '2026-06-25 16:00:00', '数据核对无误', 1, '2026-06-21 09:01:00'),
('RD-202606-013', 13, 3, '2026-06', '527631.88', '534200.00', '6568.12', '2026-06-26 11:04:00', '/uploads/seed/meter/03.jpg', '正常', NULL, '-0.72', 'PASS', 2, '2026-06-26 16:00:00', '数据核对无误', 1, '2026-06-22 09:02:00'),
('RD-202606-014', 14, 4, '2026-06', '42428.75', '42905.00', '476.25', '2026-06-27 12:06:00', '/uploads/seed/meter/04.jpg', '正常', NULL, '2.38', 'PASS', 2, '2026-06-27 16:00:00', '数据核对无误', 1, '2026-06-23 09:03:00'),
('RD-202606-015', 15, 5, '2026-06', '12349.37', '12486.00', '136.63', '2026-06-28 13:08:00', '/uploads/seed/meter/05.jpg', '正常', NULL, '0.79', 'PASS', 2, '2026-06-28 16:00:00', '数据核对无误', 1, '2026-06-24 09:04:00'),
('RD-202606-016', 16, 6, '2026-06', '95454.44', '96420.00', '965.56', '2026-06-24 14:10:00', '/uploads/seed/meter/06.jpg', '正常', NULL, '-7.30', 'PASS', 2, '2026-06-24 16:00:00', '数据核对无误', 1, '2026-06-20 09:05:00'),
('RD-202606-017', 17, 7, '2026-06', '18261.56', '18420.00', '158.44', '2026-06-25 15:12:00', '/uploads/seed/meter/07.jpg', '正常', NULL, '-1.96', 'PASS', 2, '2026-06-25 16:00:00', '数据核对无误', 1, '2026-06-21 09:06:00'),
('RD-202606-018', 18, 8, '2026-06', '15698.61', '15840.00', '141.39', '2026-06-26 16:14:00', '/uploads/seed/meter/08.jpg', '正常', NULL, '-4.18', 'PASS', 2, '2026-06-26 16:00:00', '数据核对无误', 1, '2026-06-22 09:07:00'),
('RD-202606-019', 19, 9, '2026-06', '6652.66', '6742.00', '89.34', '2026-06-27 09:16:00', '/uploads/seed/meter/01.jpg', '正常', NULL, '6.34', 'PASS', 2, '2026-06-27 16:00:00', '数据核对无误', 1, '2026-06-23 09:08:00'),
('RD-202606-020', 20, 10, '2026-06', '244571.73', '246800.00', '2228.27', '2026-06-28 10:18:00', '/uploads/seed/meter/02.jpg', '正常', NULL, '0.84', 'PASS', 2, '2026-06-28 16:00:00', '数据核对无误', 1, '2026-06-24 09:09:00'),
('RD-202607-021', 21, 1, '2026-07', '778986.98', '786540.00', '7553.02', '2026-07-24 09:00:00', '/uploads/seed/meter/01.jpg', '正常', NULL, '-6.65', 'PASS', 2, '2026-07-24 16:00:00', '数据核对无误', 1, '2026-07-20 09:00:00'),
('RD-202607-022', 22, 2, '2026-07', '947304.28', '962400.00', '15095.72', '2026-07-25 10:02:00', '/uploads/seed/meter/02.jpg', '正常', NULL, '5.72', 'PASS', 2, '2026-07-25 16:00:00', '数据核对无误', 1, '2026-07-21 09:01:00'),
('RD-202607-023', 23, 3, '2026-07', '85124.73', '86412.00', '1287.27', '2026-07-26 11:04:00', '/uploads/seed/meter/03.jpg', '正常', NULL, '3.85', 'PASS', 2, '2026-07-26 16:00:00', '数据核对无误', 1, '2026-07-22 09:02:00'),
('RD-202607-024', 24, 4, '2026-07', '1175775.92', '1187640.00', '11864.08', '2026-07-27 12:06:00', '/uploads/seed/meter/04.jpg', '正常', NULL, '2.21', 'PASS', 2, '2026-07-27 16:00:00', '数据核对无误', 1, '2026-07-23 09:03:00'),
('RD-202607-025', 25, 5, '2026-07', '315185.12', '318760.00', '3574.88', '2026-07-28 13:08:00', '/uploads/seed/meter/05.jpg', '正常', NULL, '0.85', 'PASS', 2, '2026-07-28 16:00:00', '数据核对无误', 1, '2026-07-24 09:04:00'),
('RD-202607-026', 26, 6, '2026-07', '42487.11', '42860.00', '372.89', '2026-07-24 14:10:00', '/uploads/seed/meter/06.jpg', '正常', NULL, '1.12', 'PASS', 2, '2026-07-24 16:00:00', '数据核对无误', 1, '2026-07-20 09:05:00'),
('RD-202607-027', 27, 7, '2026-07', '416604.28', '421800.00', '5195.72', '2026-07-25 15:12:00', '/uploads/seed/meter/07.jpg', '正常', NULL, '7.41', 'PASS', 2, '2026-07-25 16:00:00', '数据核对无误', 1, '2026-07-21 09:06:00'),
('RD-202607-028', 28, 8, '2026-07', '8519.48', '8620.00', '100.52', '2026-07-26 16:14:00', '/uploads/seed/meter/08.jpg', '正常', NULL, '2.11', 'PASS', 2, '2026-07-26 16:00:00', '数据核对无误', 1, '2026-07-22 09:07:00'),
('RD-202607-029', 29, 9, '2026-07', '184096.72', '186420.00', '2323.28', '2026-07-27 09:16:00', '/uploads/seed/meter/01.jpg', '正常', NULL, '0.03', 'PASS', 2, '2026-07-27 16:00:00', '数据核对无误', 1, '2026-07-23 09:08:00'),
('RD-202607-030', 30, 10, '2026-07', '126839.52', '128460.00', '1620.48', '2026-07-28 10:18:00', '/uploads/seed/meter/02.jpg', '正常', NULL, '-7.13', 'PASS', 2, '2026-07-28 16:00:00', '数据核对无误', 1, '2026-07-24 09:09:00'),
('RD-202608-031', 31, 1, '2026-08', '42372.99', '42860.00', '487.01', '2026-08-24 09:00:00', '/uploads/seed/meter/01.jpg', '正常', NULL, '-5.58', 'PASS', 2, '2026-08-24 16:00:00', '数据核对无误', 1, '2026-08-20 09:00:00'),
('RD-202608-032', 32, 2, '2026-08', '528849.93', '534200.00', '5350.07', '2026-08-25 10:02:00', '/uploads/seed/meter/02.jpg', '正常', NULL, '6.69', 'PASS', 2, '2026-08-25 16:00:00', '数据核对无误', 1, '2026-08-21 09:01:00'),
('RD-202608-033', 33, 3, '2026-08', '42318.80', '42905.00', '586.20', '2026-08-26 11:04:00', '/uploads/seed/meter/03.jpg', '正常', NULL, '4.69', 'PASS', 2, '2026-08-26 16:00:00', '数据核对无误', 1, '2026-08-22 09:02:00'),
('RD-202608-034', 34, 4, '2026-08', '12385.92', '12486.00', '100.08', '2026-08-27 12:06:00', '/uploads/seed/meter/04.jpg', '正常', NULL, '2.57', 'PASS', 2, '2026-08-27 16:00:00', '数据核对无误', 1, '2026-08-23 09:03:00'),
('RD-202608-035', 35, 5, '2026-08', '95429.46', '96420.00', '990.54', '2026-08-28 13:08:00', '/uploads/seed/meter/05.jpg', '正常', NULL, '-4.83', 'PASS', 2, '2026-08-28 16:00:00', '数据核对无误', 1, '2026-08-24 09:04:00'),
('RD-202608-036', 36, 6, '2026-08', '18237.42', '18420.00', '182.58', '2026-08-24 14:10:00', '/uploads/seed/meter/06.jpg', '正常', NULL, '3.52', 'PASS', 2, '2026-08-24 16:00:00', '数据核对无误', 1, '2026-08-20 09:05:00'),
('RD-202608-037', 37, 7, '2026-08', '15646.38', '15840.00', '193.62', '2026-08-25 15:12:00', '/uploads/seed/meter/07.jpg', '正常', NULL, '2.70', 'PASS', 2, '2026-08-25 16:00:00', '数据核对无误', 1, '2026-08-21 09:06:00'),
('RD-202608-038', 38, 8, '2026-08', '6650.63', '6742.00', '91.37', '2026-08-26 16:14:00', '/uploads/seed/meter/08.jpg', '正常', NULL, '-4.80', 'PASS', 2, '2026-08-26 16:00:00', '数据核对无误', 1, '2026-08-22 09:07:00'),
('RD-202608-039', 39, 9, '2026-08', '244368.45', '246800.00', '2431.55', '2026-08-27 09:16:00', '/uploads/seed/meter/01.jpg', '正常', NULL, '0.96', 'PASS', 2, '2026-08-27 16:00:00', '数据核对无误', 1, '2026-08-23 09:08:00'),
('RD-202608-040', 40, 10, '2026-08', '85308.20', '86420.00', '1111.80', '2026-08-28 10:18:00', '/uploads/seed/meter/02.jpg', '正常', NULL, '5.11', 'PASS', 2, '2026-08-28 16:00:00', '数据核对无误', 1, '2026-08-24 09:09:00'),
('RD-202609-041', 41, 1, '2026-09', '950977.40', '962400.00', '11422.60', '2026-09-24 09:00:00', '/uploads/seed/meter/01.jpg', '正常', NULL, '-0.63', 'PASS', 2, '2026-09-24 16:00:00', '数据核对无误', 1, '2026-09-20 09:00:00'),
('RD-202609-042', 42, 2, '2026-09', '85683.37', '86412.00', '728.63', '2026-09-25 10:02:00', '/uploads/seed/meter/02.jpg', '正常', NULL, '-7.75', 'PASS', 2, '2026-09-25 16:00:00', '数据核对无误', 1, '2026-09-21 09:01:00'),
('RD-202609-043', 43, 3, '2026-09', '1169257.83', '1187640.00', '18382.17', '2026-09-26 11:04:00', '/uploads/seed/meter/03.jpg', '正常', NULL, '4.14', 'PENDING', NULL, NULL, NULL, 0, '2026-09-22 09:02:00'),
('RD-202609-044', 44, 4, '2026-09', '314257.28', '318760.00', '4502.72', '2026-09-27 12:06:00', '/uploads/seed/meter/04.jpg', '异常', '读数较均值明显偏高，待复核', '1.05', 'PENDING', NULL, NULL, NULL, 0, '2026-09-23 09:03:00'),
('RD-202609-045', 45, 5, '2026-09', '42494.36', '42860.00', '365.64', '2026-09-28 13:08:00', '/uploads/seed/meter/05.jpg', '正常', NULL, '5.77', 'REJECT', 2, '2026-09-28 16:00:00', '现场照片模糊，请重拍并核对表盘', 0, '2026-09-24 09:04:00'),
('RD-202609-046', 47, 7, '2026-09', '8534.89', '8620.00', '85.11', '2026-09-25 15:12:00', '/uploads/seed/meter/07.jpg', '正常', NULL, '1.72', 'PASS', 2, '2026-09-25 16:00:00', '数据核对无误', 1, '2026-09-21 09:06:00'),
('RD-202609-047', 48, 8, '2026-09', '183743.45', '186420.00', '2676.55', '2026-09-26 16:14:00', '/uploads/seed/meter/08.jpg', '正常', NULL, '-6.70', 'PASS', 2, '2026-09-26 16:00:00', '数据核对无误', 1, '2026-09-22 09:07:00'),
('RD-202609-048', 49, 9, '2026-09', '126651.41', '128460.00', '1808.59', '2026-09-27 09:16:00', '/uploads/seed/meter/01.jpg', '正常', NULL, '-3.82', 'PENDING', NULL, NULL, NULL, 0, '2026-09-23 09:08:00'),
('RD-202610-049', 52, 3, '2026-10', '778478.64', '786540.00', '8061.36', '2026-10-26 11:04:00', '/uploads/seed/meter/03.jpg', '正常', NULL, '-4.59', 'PENDING', NULL, NULL, NULL, 0, '2026-10-22 09:02:00'),
('RD-202610-050', 53, 4, '2026-10', '42225.53', '43126.48', '900.95', '2026-10-27 12:06:00', '/uploads/seed/meter/04.jpg', '异常', '读数较均值明显偏高，待复核', '35.06', 'PENDING', NULL, NULL, NULL, 0, '2026-10-23 09:03:00'),
('RD-202610-051', 54, 5, '2026-10', '950015.38', '962400.00', '12384.62', '2026-10-28 13:08:00', '/uploads/seed/meter/05.jpg', '正常', NULL, '-1.61', 'PASS', 2, '2026-10-28 16:00:00', '数据核对无误', 1, '2026-10-24 09:04:00'),
('RD-202610-S052', 54, 5, '2026-10', '962280.00', '962400.00', '120.00', '2026-10-28 10:20:00', '/uploads/seed/meter/05.jpg', '正常', '补抄上期遗漏读数', '0.00', 'PASS', 2, '2026-10-28 11:00:00', '补抄确认', 0, '2026-10-27 17:00:00'),
('RD-202610-053', 55, 6, '2026-10', '526704.16', '534200.00', '7495.84', '2026-10-24 14:10:00', '/uploads/seed/meter/06.jpg', '正常', NULL, '4.15', 'PASS', 2, '2026-10-24 16:00:00', '数据核对无误', 1, '2026-10-20 09:05:00'),
('RD-202610-054', 56, 7, '2026-10', '85150.79', '86412.00', '1261.21', '2026-10-25 15:12:00', '/uploads/seed/meter/07.jpg', '正常', NULL, '1.91', 'REJECT', 2, '2026-10-25 16:00:00', '现场照片模糊，请重拍并核对表盘', 0, '2026-10-21 09:06:00'),
('RD-202610-055', 58, 9, '2026-10', '1170315.39', '1187640.00', '17324.61', '2026-10-27 09:16:00', '/uploads/seed/meter/01.jpg', '正常', NULL, '4.23', 'PENDING', NULL, NULL, NULL, 0, '2026-10-23 09:08:00'),
('RD-202610-056', 62, 13, '2026-10', '42346.17', '42860.00', '513.83', '2026-10-26 13:24:00', '/uploads/seed/meter/05.jpg', '正常', NULL, '-3.75', 'PENDING', NULL, NULL, NULL, 0, '2026-10-22 09:12:00'),
('RD-202610-057', 63, 14, '2026-10', '18148.39', '18534.08', '385.69', '2026-10-27 14:26:00', '/uploads/seed/meter/06.jpg', '异常', '读数较均值明显偏高，待复核', '35.15', 'PENDING', NULL, NULL, NULL, 0, '2026-10-23 09:13:00'),
('RD-202610-058', 64, 15, '2026-10', '415806.12', '421800.00', '5993.88', '2026-10-28 15:28:00', '/uploads/seed/meter/07.jpg', '正常', NULL, '5.36', 'PASS', 2, '2026-10-28 16:00:00', '数据核对无误', 1, '2026-10-24 09:14:00'),
('RD-202610-059', 65, 16, '2026-10', '15669.65', '15840.00', '170.35', '2026-10-24 16:30:00', '/uploads/seed/meter/08.jpg', '正常', NULL, '-1.60', 'PASS', 2, '2026-10-24 16:00:00', '数据核对无误', 1, '2026-10-20 09:15:00'),
('RD-202610-060', 66, 17, '2026-10', '8485.00', '8620.00', '135.00', '2026-10-25 09:32:00', '/uploads/seed/meter/01.jpg', '正常', NULL, '-4.48', 'REJECT', 2, '2026-10-25 16:00:00', '现场照片模糊，请重拍并核对表盘', 0, '2026-10-21 09:16:00'),
('RD-202610-061', 68, 19, '2026-10', '184112.17', '186420.00', '2307.83', '2026-10-27 11:36:00', '/uploads/seed/meter/03.jpg', '正常', NULL, '5.70', 'PENDING', NULL, NULL, NULL, 0, '2026-10-23 09:18:00');

INSERT INTO `energy_bill` (`bill_no`, `building_id`, `meter_id`, `energy_type`, `period`, `usage_amount`, `unit_price`, `amount`, `adjust_amount`, `final_amount`, `status`, `lock_flag`, `tariff_version`, `create_time`) VALUES
('BILL-202608-001', 1, 4, 'WATER', '2026-08', '100.08', '3.4500', '345.28', '0.00', '345.28', '已确认', 1, 'v2026.10', '2026-10-10 10:00:00'),
('BILL-202608-002', 2, 5, 'ELEC', '2026-08', '990.54', '0.7100', '703.28', '0.00', '703.28', '已确认', 1, 'v2026.10', '2026-10-11 10:00:00'),
('BILL-202608-003', 2, 6, 'ELEC', '2026-08', '182.58', '0.7100', '129.63', '0.00', '129.63', '已锁定', 1, 'v2026.10', '2026-10-12 10:00:00'),
('BILL-202608-004', 2, 7, 'WATER', '2026-08', '193.62', '3.4500', '667.99', '0.00', '667.99', '已调整', 1, 'v2026.10', '2026-10-13 10:00:00'),
('BILL-202608-005', 2, 8, 'GAS', '2026-08', '91.37', '3.1000', '283.25', '0.00', '283.25', '已确认', 1, 'v2026.10', '2026-10-14 10:00:00'),
('BILL-202608-006', 7, 9, 'ELEC', '2026-08', '2431.55', '0.7100', '1726.40', '0.00', '1726.40', '已确认', 1, 'v2026.10', '2026-10-15 10:00:00'),
('BILL-202608-007', 7, 10, 'COOL', '2026-08', '1111.80', '42.0000', '46695.60', '0.00', '46695.60', '已锁定', 1, 'v2026.10', '2026-10-16 10:00:00'),
('BILL-202609-008', 1, 1, 'ELEC', '2026-09', '11422.60', '0.7100', '8110.05', '0.00', '8110.05', '已调整', 1, 'v2026.10', '2026-10-17 10:00:00'),
('BILL-202609-009', 1, 2, 'ELEC', '2026-09', '728.63', '0.7100', '517.33', '0.00', '517.33', '已确认', 1, 'v2026.10', '2026-10-18 10:00:00'),
('BILL-202609-010', 2, 7, 'WATER', '2026-09', '85.11', '3.4500', '293.63', '0.00', '293.63', '已确认', 1, 'v2026.10', '2026-10-19 10:00:00'),
('BILL-202609-011', 2, 8, 'GAS', '2026-09', '2676.55', '3.1000', '8297.31', '0.00', '8297.31', '已锁定', 1, 'v2026.10', '2026-10-20 10:00:00'),
('BILL-202610-012', 2, 5, 'ELEC', '2026-10', '12384.62', '0.7100', '8793.08', '0.00', '8793.08', '已调整', 1, 'v2026.10', '2026-10-21 10:00:00'),
('BILL-202610-013', 2, 5, 'ELEC', '2026-10', '120.00', '0.7100', '85.20', '0.00', '85.20', '已确认', 1, 'v2026.10', '2026-10-22 10:00:00'),
('BILL-202610-014', 2, 6, 'ELEC', '2026-10', '7495.84', '0.7100', '5322.05', '0.00', '5322.05', '已确认', 1, 'v2026.10', '2026-10-23 10:00:00'),
('BILL-202610-015', 4, 15, 'ELEC', '2026-10', '5993.88', '0.7100', '4255.65', '0.00', '4255.65', '已锁定', 1, 'v2026.10', '2026-10-24 10:00:00'),
('BILL-202610-016', 4, 16, 'GAS', '2026-10', '170.35', '3.1000', '528.09', '0.00', '528.09', '已调整', 1, 'v2026.10', '2026-10-25 10:00:00');

INSERT INTO `energy_exception` (`exception_no`, `meter_id`, `reading_id`, `building_id`, `exception_type`, `level`, `trigger_rule`, `description`, `handler_id`, `status`, `cause`, `handle_note`, `close_time`, `create_time`) VALUES
('EX-20261028-003', 11, NULL, 3, 'SURGE', 'HIGH', '本期用量 21,480 kWh，较近 6 期均值 15,920 kWh 增长 34.9%，超过 25% 阈值', '教学楼总表用量突增', 2, 'OPEN', NULL, NULL, NULL, '2026-10-05 09:00:00'),
('EX-20261027-002', 18, NULL, 5, 'FLAT', 'MID', '连续 3 期用量变化为 0，疑似表计卡死', '图书馆给水表长期不变', 2, 'HANDLING', '表计老化', '已派检定工单，等待更换', NULL, '2026-10-06 09:00:00'),
('EX-20261026-001', 20, NULL, 6, 'DROP', 'MID', '本期用量较均值下降 28.4%，超过 25% 阈值', '疾控中心总表用量突降', 2, 'OPEN', NULL, NULL, NULL, '2026-10-07 09:00:00'),
('EX-20261020-004', 10, NULL, 7, 'DAMAGE', 'HIGH', '表盘玻璃破裂，读数无法辨识', '住院楼冷热量表损坏', 2, 'CLOSED', '外力碰撞', '已更换表计，历史读数按均值推算', '2026-10-28 16:00:00', '2026-10-08 09:00:00'),
('EX-20260925-005', 15, NULL, 4, 'SURGE', 'MID', '本期用量超均值 22.6%', '政务中心总表偏高', 2, 'CLOSED', '空调季延长', '核实为合理增长，已纳入定额调整', '2026-10-28 16:00:00', '2026-10-09 09:00:00'),
('EX-20260918-006', 2, NULL, 1, 'CASCADE', 'HIGH', '下级 6 块子表合计 21,480 kWh 大于总表 20,960 kWh', '级联校验不通过', 2, 'CLOSED', '子表重复计量', '已调整子表倍率并重新核算', '2026-10-28 16:00:00', '2026-10-10 09:00:00'),
('EX-20260822-007', 8, NULL, 2, 'SURGE', 'HIGH', '燃气用量较均值增长 41.2%', '食堂燃气异常', 2, 'CLOSED', '食堂设备改造', '改造期用气增加，已备案', '2026-10-28 16:00:00', '2026-10-11 09:00:00'),
('EX-20260815-008', 3, NULL, 1, 'FLAT', 'MID', '连续 2 期用量为 0', '行政中心空调用量归零', 2, 'IGNORED', '空调停机检修', '检修期无用量，属正常', NULL, '2026-10-12 09:00:00'),
('EX-20260720-009', 17, NULL, 4, 'DROP', 'MID', '用量下降 31.5%', '政务中心冷站用量下降', 2, 'CLOSED', '冷站停用', '设备停用，已办理报停', '2026-10-28 16:00:00', '2026-10-13 09:00:00'),
('EX-20260712-010', 4, NULL, 1, 'SURGE', 'MID', '用水量超均值 26.8%', '行政中心用水偏高', 2, 'CLOSED', '管道维修补水', '已修复漏点', '2026-10-28 16:00:00', '2026-10-14 09:00:00'),
('EX-20260628-011', 12, NULL, 3, 'SURGE', 'HIGH', '用电量增长 38.2%', '教学楼A区照明异常', 2, 'CLOSED', '暑期施工用电', '施工临时用电，已登记', '2026-10-28 16:00:00', '2026-10-15 09:00:00'),
('EX-20260610-012', 5, NULL, 2, 'DAMAGE', 'MID', '表计通讯模块故障', '门诊楼总表数据缺失', 2, 'CLOSED', '模块故障', '已更换模块', '2026-10-28 16:00:00', '2026-10-16 09:00:00');

INSERT INTO `energy_quota` (`quota_no`, `target_type`, `target_id`, `target_name`, `energy_type`, `period_type`, `quota_value`, `used_value`, `year`) VALUES
('QU-2026-001', 'BUILDING', 3, '实验中学教学楼', 'ELEC', 'YEAR', 240000, 186420, 2026),
('QU-2026-002', 'BUILDING', 2, '第一人民医院门诊楼', 'ELEC', 'YEAR', 1400000, 962400, 2026),
('QU-2026-003', 'BUILDING', 1, '行政中心A座', 'ELEC', 'YEAR', 1600000, 1284320, 2026),
('QU-2026-004', 'BUILDING', 4, '政务服务中心', 'ELEC', 'YEAR', 560000, 421800, 2026),
('QU-2026-005', 'BUILDING', 5, '图书馆', 'WATER', 'YEAR', 8000, 6742, 2026),
('QU-2026-006', 'BUILDING', 7, '第一人民医院住院楼', 'ELEC', 'YEAR', 1500000, 1187640, 2026),
('QU-2026-007', 'BUILDING', 6, '疾控中心实验楼', 'ELEC', 'YEAR', 320000, 246800, 2026),
('QU-2026-008', 'BUILDING', 8, '实验中学体育馆', 'ELEC', 'YEAR', 120000, 86420, 2026),
('QU-2026-009', 'BUILDING', 1, '行政中心A座', 'WATER', 'YEAR', 60000, 42860, 2026),
('QU-2026-010', 'BUILDING', 2, '第一人民医院门诊楼', 'WATER', 'YEAR', 100000, 86412, 2026),
('QU-2026-011', 'BUILDING', 4, '政务服务中心', 'GAS', 'YEAR', 22000, 15840, 2026),
('QU-2026-012', 'BUILDING', 3, '实验中学教学楼', 'WATER', 'YEAR', 26000, 18420, 2026);

INSERT INTO `saving_measure` (`measure_no`, `measure_name`, `building_id`, `content`, `invest_amount`, `plan_start`, `plan_end`, `target_saving`, `actual_saving`, `status`, `owner_id`) VALUES
('MS-2026-001', '教学楼照明 LED 改造', 3, '将 1-5F 荧光灯更换为 LED 灯具并加装分区控制', 68.0, '2026-03-01', '2026-06-30', 12.5, 9.8, '已验收', 2),
('MS-2026-002', '中央空调群控优化', 1, '冷站群控策略由定频改为变频联动，优化启停时序', 42.0, '2026-05-01', '2026-09-30', 18.0, 15.2, '实施中', 2),
('MS-2026-003', '门诊楼热水系统空气源改造', 2, '燃气锅炉替换为空气源热泵，配套储热水箱', 126.0, '2026-04-01', '2026-11-30', 32.0, NULL, '实施中', 2),
('MS-2026-004', '卫生间感应节水器安装', 5, '阅览区与公共卫生间加装感应龙头 46 套', 9.6, '2026-07-01', '2026-08-31', 1.8, 1.6, '已验收', 2),
('MS-2026-005', '配电分项计量补齐', 4, '补齐 12 个分项计量点，实现按楼层分项统计', 35.0, '2026-09-01', '2026-12-31', NULL, NULL, '待启动', 2),
('MS-2026-006', '住院楼电梯能量回馈', 7, '2 台电梯加装能量回馈装置', 18.0, '2026-06-01', '2026-09-15', 6.4, 5.9, '已验收', 2),
('MS-2026-007', '屋面光伏示范', 6, '实验楼屋面铺设 60kW 光伏，自发自用', 48.0, '2026-08-01', '2027-03-31', 22.0, NULL, '实施中', 2),
('MS-2026-008', '围护结构外窗改造', 8, '体育馆外窗更换为 Low-E 中空玻璃', 56.0, '2026-10-01', '2027-01-31', 14.0, NULL, '待启动', 2);

INSERT INTO `baseline_rule` (`rule_name`, `version`, `weights_json`, `threshold_json`, `status`, `effective_time`, `create_by`) VALUES
('能耗基线偏差识别', 'v1', '{"histMean":40,"stdDev":20,"area":15,"person":10,"season":10,"growth":5}', '{"high":80,"mid":55}', 'DISABLED', '2026-03-01 09:00:00', '张立'),
('能耗基线偏差识别', 'v2', '{"histMean":35,"stdDev":20,"area":15,"person":15,"season":10,"growth":5}', '{"high":78,"mid":52}', 'DISABLED', '2026-06-01 09:00:00', '张立'),
('能耗基线偏差识别', 'v3', '{"histMean":30,"stdDev":20,"area":15,"person":15,"season":10,"growth":10}', '{"high":75,"mid":50}', 'ENABLED', '2026-09-15 09:00:00', '张立');

INSERT INTO `baseline_score` (`score_no`, `building_id`, `meter_id`, `energy_type`, `period`, `rule_id`, `rule_version`, `input_json`, `item_json`, `total_score`, `level`, `conclusion`, `main_factors`, `unmet_json`, `improve_json`, `adopt_flag`, `adjust_level`, `adjust_reason`, `adjust_by`, `adjust_time`, `calc_time`) VALUES
('BL-202605-0100', 1, 1, 'ELEC', '2026-05', 3, 'v3', '{"currUsage":"22599.43","baseMean":"13583.05","baseStd":"1240.00","buildArea":"33946.7","personCount":2882,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 81.0, 'HIGH', '本期单位面积能耗超出近 6 期基线波动范围，建议核查设备运行与计量回路', '当前读数增长率 90.0 分；标准波动 82.0 分；历史均值 78.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 1, NULL, NULL, NULL, NULL, '2026-05-08 10:00:00'),
('BL-202606-0101', 2, 2, 'ELEC', '2026-06', 3, 'v3', '{"currUsage":"22348.07","baseMean":"17158.14","baseStd":"1240.00","buildArea":"31416.73","personCount":490,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 89.6, 'HIGH', '本期单位面积能耗超出近 6 期基线波动范围，建议核查设备运行与计量回路', '当前读数增长率 90.0 分；标准波动 82.0 分；历史均值 78.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 0, NULL, NULL, NULL, NULL, '2026-06-09 10:01:00'),
('BL-202607-0102', 3, 3, 'ELEC', '2026-07', 3, 'v3', '{"currUsage":"22215.77","baseMean":"17221.86","baseStd":"1240.00","buildArea":"25730.2","personCount":2600,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 84.8, 'HIGH', '本期单位面积能耗超出近 6 期基线波动范围，建议核查设备运行与计量回路', '当前读数增长率 90.0 分；标准波动 82.0 分；历史均值 78.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 0, NULL, NULL, NULL, NULL, '2026-07-10 10:02:00'),
('BL-202608-0103', 4, 4, 'ELEC', '2026-08', 3, 'v3', '{"currUsage":"15415.14","baseMean":"12541.92","baseStd":"1240.00","buildArea":"21355.59","personCount":1345,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 75.4, 'HIGH', '本期单位面积能耗超出近 6 期基线波动范围，建议核查设备运行与计量回路', '当前读数增长率 90.0 分；标准波动 82.0 分；历史均值 78.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 1, 'MID', '经设备科确认为实训室新增空调，属合理增长，下调为偏高', '张立', '2026-10-28 11:20:00', '2026-08-11 10:03:00'),
('BL-202609-0104', 5, 5, 'ELEC', '2026-09', 3, 'v3', '{"currUsage":"25524.54","baseMean":"14858.58","baseStd":"1240.00","buildArea":"14327.43","personCount":1376,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 81.3, 'HIGH', '本期单位面积能耗超出近 6 期基线波动范围，建议核查设备运行与计量回路', '当前读数增长率 90.0 分；标准波动 82.0 分；历史均值 78.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 0, NULL, NULL, NULL, NULL, '2026-09-12 10:04:00'),
('BL-202610-0105', 6, 6, 'ELEC', '2026-10', 3, 'v3', '{"currUsage":"16054.6","baseMean":"17635.6","baseStd":"1240.00","buildArea":"22998.7","personCount":1509,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 79.2, 'HIGH', '本期单位面积能耗超出近 6 期基线波动范围，建议核查设备运行与计量回路', '当前读数增长率 90.0 分；标准波动 82.0 分；历史均值 78.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 0, NULL, NULL, NULL, NULL, '2026-10-13 10:05:00'),
('BL-202605-0106', 7, 7, 'ELEC', '2026-05', 3, 'v3', '{"currUsage":"21915.34","baseMean":"13060.32","baseStd":"1240.00","buildArea":"34319.3","personCount":1409,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 83.4, 'HIGH', '本期单位面积能耗超出近 6 期基线波动范围，建议核查设备运行与计量回路', '当前读数增长率 90.0 分；标准波动 82.0 分；历史均值 78.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 1, NULL, NULL, NULL, NULL, '2026-05-14 10:06:00'),
('BL-202606-0107', 8, 8, 'ELEC', '2026-06', 3, 'v3', '{"currUsage":"16079.94","baseMean":"14043.39","baseStd":"1240.00","buildArea":"6259.09","personCount":3187,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 91.0, 'HIGH', '本期单位面积能耗超出近 6 期基线波动范围，建议核查设备运行与计量回路', '当前读数增长率 90.0 分；标准波动 82.0 分；历史均值 78.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 0, NULL, NULL, NULL, NULL, '2026-06-15 10:07:00'),
('BL-202607-0108', 1, 9, 'ELEC', '2026-07', 3, 'v3', '{"currUsage":"19043.06","baseMean":"12021.67","baseStd":"1240.00","buildArea":"17872.92","personCount":1529,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 78.0, 'HIGH', '本期单位面积能耗超出近 6 期基线波动范围，建议核查设备运行与计量回路', '当前读数增长率 90.0 分；标准波动 82.0 分；历史均值 78.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 0, NULL, NULL, NULL, NULL, '2026-07-16 10:08:00'),
('BL-202608-0109', 2, 10, 'ELEC', '2026-08', 3, 'v3', '{"currUsage":"16935.48","baseMean":"15458.22","baseStd":"1240.00","buildArea":"31687.38","personCount":1833,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 58.3, 'MID', '本期能耗高于基线但仍在可解释范围内，建议关注后续两期走势', '历史均值 62.0 分；建筑面积 58.0 分；季节系数 46.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 1, NULL, NULL, NULL, NULL, '2026-08-17 10:09:00'),
('BL-202609-0110', 3, 11, 'ELEC', '2026-09', 3, 'v3', '{"currUsage":"16879.58","baseMean":"12197.23","baseStd":"1240.00","buildArea":"5952.96","personCount":2806,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 65.4, 'MID', '本期能耗高于基线但仍在可解释范围内，建议关注后续两期走势', '历史均值 62.0 分；建筑面积 58.0 分；季节系数 46.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 0, NULL, NULL, NULL, NULL, '2026-09-18 10:10:00'),
('BL-202610-0111', 4, 12, 'ELEC', '2026-10', 3, 'v3', '{"currUsage":"19002.27","baseMean":"16051.75","baseStd":"1240.00","buildArea":"29847.86","personCount":412,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 67.1, 'MID', '本期能耗高于基线但仍在可解释范围内，建议关注后续两期走势', '历史均值 62.0 分；建筑面积 58.0 分；季节系数 46.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 0, NULL, NULL, NULL, NULL, '2026-10-19 10:11:00'),
('BL-202605-0112', 5, 13, 'ELEC', '2026-05', 3, 'v3', '{"currUsage":"17451.69","baseMean":"11388.72","baseStd":"1240.00","buildArea":"22359.66","personCount":2870,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 53.5, 'MID', '本期能耗高于基线但仍在可解释范围内，建议关注后续两期走势', '历史均值 62.0 分；建筑面积 58.0 分；季节系数 46.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 1, NULL, NULL, NULL, NULL, '2026-05-20 10:12:00'),
('BL-202606-0113', 6, 14, 'ELEC', '2026-06', 3, 'v3', '{"currUsage":"24936.82","baseMean":"11076.07","baseStd":"1240.00","buildArea":"14817.53","personCount":1066,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 57.1, 'MID', '本期能耗高于基线但仍在可解释范围内，建议关注后续两期走势', '历史均值 62.0 分；建筑面积 58.0 分；季节系数 46.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 0, NULL, NULL, NULL, NULL, '2026-06-21 10:13:00'),
('BL-202607-0114', 7, 15, 'ELEC', '2026-07', 3, 'v3', '{"currUsage":"13820.88","baseMean":"16865.72","baseStd":"1240.00","buildArea":"26564.49","personCount":2705,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 62.4, 'MID', '本期能耗高于基线但仍在可解释范围内，建议关注后续两期走势', '历史均值 62.0 分；建筑面积 58.0 分；季节系数 46.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 0, NULL, NULL, NULL, NULL, '2026-07-22 10:14:00'),
('BL-202608-0115', 8, 16, 'ELEC', '2026-08', 3, 'v3', '{"currUsage":"19912.93","baseMean":"13508.95","baseStd":"1240.00","buildArea":"9209.13","personCount":2794,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 54.0, 'MID', '本期能耗高于基线但仍在可解释范围内，建议关注后续两期走势', '历史均值 62.0 分；建筑面积 58.0 分；季节系数 46.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 1, NULL, NULL, NULL, NULL, '2026-08-23 10:15:00'),
('BL-202609-0116', 1, 17, 'ELEC', '2026-09', 3, 'v3', '{"currUsage":"18935.71","baseMean":"16906.37","baseStd":"1240.00","buildArea":"28502.9","personCount":2774,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 61.2, 'MID', '本期能耗高于基线但仍在可解释范围内，建议关注后续两期走势', '历史均值 62.0 分；建筑面积 58.0 分；季节系数 46.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 0, NULL, NULL, NULL, NULL, '2026-09-24 10:16:00'),
('BL-202610-0117', 2, 18, 'ELEC', '2026-10', 3, 'v3', '{"currUsage":"21676.42","baseMean":"12624.4","baseStd":"1240.00","buildArea":"34678.95","personCount":2073,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 55.9, 'MID', '本期能耗高于基线但仍在可解释范围内，建议关注后续两期走势', '历史均值 62.0 分；建筑面积 58.0 分；季节系数 46.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 0, NULL, NULL, NULL, NULL, '2026-10-25 10:17:00'),
('BL-202605-0118', 3, 19, 'ELEC', '2026-05', 3, 'v3', '{"currUsage":"14895.67","baseMean":"11687.88","baseStd":"1240.00","buildArea":"27239.25","personCount":575,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 70.3, 'MID', '本期能耗高于基线但仍在可解释范围内，建议关注后续两期走势', '历史均值 62.0 分；建筑面积 58.0 分；季节系数 46.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 1, NULL, NULL, NULL, NULL, '2026-05-08 10:18:00'),
('BL-202606-0119', 4, 20, 'ELEC', '2026-06', 3, 'v3', '{"currUsage":"23890.83","baseMean":"11359.49","baseStd":"1240.00","buildArea":"35660.32","personCount":2604,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 59.4, 'MID', '本期能耗高于基线但仍在可解释范围内，建议关注后续两期走势', '历史均值 62.0 分；建筑面积 58.0 分；季节系数 46.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 0, NULL, NULL, NULL, NULL, '2026-06-09 10:19:00'),
('BL-202607-0120', 5, 21, 'ELEC', '2026-07', 3, 'v3', '{"currUsage":"21774.34","baseMean":"17838.67","baseStd":"1240.00","buildArea":"36670.91","personCount":603,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 73.5, 'MID', '本期能耗高于基线但仍在可解释范围内，建议关注后续两期走势', '历史均值 62.0 分；建筑面积 58.0 分；季节系数 46.0 分', '["缺少本月设备增减说明"]', '["补充设备增减说明与配电回路核查记录","核对分项计量覆盖率"]', 0, NULL, NULL, NULL, NULL, '2026-07-10 10:20:00'),
('BL-202608-0121', 6, 22, 'ELEC', '2026-08', 3, 'v3', '{"currUsage":"13791.82","baseMean":"12150.12","baseStd":"1240.00","buildArea":"9064.01","personCount":1868,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 39.9, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 1, NULL, NULL, NULL, NULL, '2026-08-11 10:21:00'),
('BL-202609-0122', 7, 1, 'ELEC', '2026-09', 3, 'v3', '{"currUsage":"15724.02","baseMean":"13548.26","baseStd":"1240.00","buildArea":"25660.34","personCount":1750,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 30.7, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 0, NULL, NULL, NULL, NULL, '2026-09-12 10:22:00'),
('BL-202610-0123', 8, 2, 'ELEC', '2026-10', 3, 'v3', '{"currUsage":"24326.42","baseMean":"11044.88","baseStd":"1240.00","buildArea":"11682.1","personCount":3025,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 13.3, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 0, NULL, NULL, NULL, NULL, '2026-10-13 10:23:00'),
('BL-202605-0124', 1, 3, 'ELEC', '2026-05', 3, 'v3', '{"currUsage":"22272.46","baseMean":"14101.24","baseStd":"1240.00","buildArea":"32762.59","personCount":2717,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 40.5, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 1, NULL, NULL, NULL, NULL, '2026-05-14 10:24:00'),
('BL-202606-0125', 2, 4, 'ELEC', '2026-06', 3, 'v3', '{"currUsage":"23895.15","baseMean":"11415.88","baseStd":"1240.00","buildArea":"11064.34","personCount":2489,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 34.3, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 0, NULL, NULL, NULL, NULL, '2026-06-15 10:25:00'),
('BL-202607-0126', 3, 5, 'ELEC', '2026-07', 3, 'v3', '{"currUsage":"24891.84","baseMean":"13920.68","baseStd":"1240.00","buildArea":"25968.29","personCount":1360,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 23.2, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 0, NULL, NULL, NULL, NULL, '2026-07-16 10:26:00'),
('BL-202608-0127', 4, 6, 'ELEC', '2026-08', 3, 'v3', '{"currUsage":"20360.39","baseMean":"16473.0","baseStd":"1240.00","buildArea":"12073.31","personCount":1196,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 45.8, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 1, NULL, NULL, NULL, NULL, '2026-08-17 10:27:00'),
('BL-202609-0128', 5, 7, 'ELEC', '2026-09', 3, 'v3', '{"currUsage":"18882.6","baseMean":"11301.7","baseStd":"1240.00","buildArea":"22069.64","personCount":1689,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 38.6, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 0, NULL, NULL, NULL, NULL, '2026-09-18 10:28:00'),
('BL-202610-0129', 6, 8, 'ELEC', '2026-10', 3, 'v3', '{"currUsage":"22664.47","baseMean":"12774.68","baseStd":"1240.00","buildArea":"9241.79","personCount":1317,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 30.4, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 0, NULL, NULL, NULL, NULL, '2026-10-19 10:29:00'),
('BL-202605-0130', 7, 9, 'ELEC', '2026-05', 3, 'v3', '{"currUsage":"19877.76","baseMean":"14780.02","baseStd":"1240.00","buildArea":"30214.26","personCount":381,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 44.9, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 1, NULL, NULL, NULL, NULL, '2026-05-20 10:30:00'),
('BL-202606-0131', 8, 10, 'ELEC', '2026-06', 3, 'v3', '{"currUsage":"21794.13","baseMean":"12143.77","baseStd":"1240.00","buildArea":"35598.18","personCount":449,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 45.2, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 0, NULL, NULL, NULL, NULL, '2026-06-21 10:31:00'),
('BL-202607-0132', 1, 11, 'ELEC', '2026-07', 3, 'v3', '{"currUsage":"20795.59","baseMean":"14138.06","baseStd":"1240.00","buildArea":"32604.46","personCount":1875,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 47.9, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 0, NULL, NULL, NULL, NULL, '2026-07-22 10:32:00'),
('BL-202608-0133', 2, 12, 'ELEC', '2026-08', 3, 'v3', '{"currUsage":"17687.59","baseMean":"11661.56","baseStd":"1240.00","buildArea":"30374.08","personCount":2429,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 26.7, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 1, NULL, NULL, NULL, NULL, '2026-08-23 10:33:00'),
('BL-202609-0134', 3, 13, 'ELEC', '2026-09', 3, 'v3', '{"currUsage":"18342.8","baseMean":"12849.69","baseStd":"1240.00","buildArea":"17846.17","personCount":2627,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 34.1, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 0, NULL, NULL, NULL, NULL, '2026-09-24 10:34:00'),
('BL-202610-0135', 4, 14, 'ELEC', '2026-10', 3, 'v3', '{"currUsage":"14091.42","baseMean":"16142.42","baseStd":"1240.00","buildArea":"26955.8","personCount":2256,"seasonFactor":"1.06","basePeriods":6}', '[{"key":"histMean","label":"历史均值","weight":30,"score":78.0},{"key":"stdDev","label":"标准波动","weight":20,"score":82.0},{"key":"area","label":"建筑面积","weight":15,"score":64.0},{"key":"person","label":"使用人数","weight":15,"score":55.0},{"key":"season","label":"季节系数","weight":10,"score":40.0},{"key":"growth","label":"当前读数增长率","weight":10,"score":90.0}]', 29.2, 'LOW', '本期能耗处于基线波动范围内，无需处置', '季节系数 32.0 分；使用人数 41.0 分；历史均值 38.0 分', '[]', '["保持当前用能习惯"]', 0, NULL, NULL, NULL, NULL, '2026-10-25 10:35:00');

INSERT INTO `sys_message` (`title`, `content`, `biz_no`, `biz_type`, `receiver_id`, `is_read`, `create_time`) VALUES
('抄表任务待复核', 'TK-202610-004 已提交现场读数，请联系复核', 'TK-202610-004', 'TASK', 2, 0, '2026-10-22 08:14:00'),
('异常单待处置', 'EX-20261028-003 教学楼总表用量突增，请核查', 'EX-20261028-003', 'EXCEPTION', 2, 0, '2026-10-22 08:14:00'),
('异常单待处置', 'EX-20261026-001 疾控中心总表用量突降', 'EX-20261026-001', 'EXCEPTION', 2, 1, '2026-10-22 08:14:00'),
('账单已生成', '2026-10 月账单已生成 16 张，合计金额已入台账', NULL, 'BILL', 2, 1, '2026-10-22 08:14:00'),
('定额预警', '图书馆用水已达定额 84.3%，请关注', 'QU-2026-005', 'QUOTA', 2, 0, '2026-10-22 08:14:00'),
('抄表任务已派发', '您有 6 条 10 月抄表任务待执行，截止 10-28', NULL, 'TASK', 3, 1, '2026-10-23 08:21:00'),
('抄表任务已派发', '您有 5 条 10 月抄表任务待执行，截止 10-28', NULL, 'TASK', 4, 0, '2026-10-24 08:28:00'),
('节能措施待验收', 'MS-2026-002 中央空调群控优化已到计划结束时间', 'MS-2026-002', 'MEASURE', 2, 1, '2026-10-22 08:14:00');

INSERT INTO `sys_log` (`user_id`, `username`, `module`, `action`, `method`, `params`, `ip`, `cost_ms`, `result`, `create_time`) VALUES
(2, 'zhangli', 'Meter', 'save', 'POST /api/meter', '', '127.0.0.1', 40, 'OK', '2026-10-10 10:00:00'),
(3, 'wangjg', 'Reading', 'submit', 'POST /api/reading/submit', '', '127.0.0.1', 47, 'OK', '2026-10-11 11:04:00'),
(2, 'zhangli', 'Bill', 'generate', 'POST /api/bill/generate', '', '127.0.0.1', 54, 'OK', '2026-10-12 12:08:00'),
(3, 'wangjg', 'Baseline', 'evaluate', 'POST /api/baseline/evaluate', '', '127.0.0.1', 61, 'OK', '2026-10-13 13:12:00'),
(2, 'zhangli', 'Exception', 'handle', 'POST /api/exception/1/handle', '', '127.0.0.1', 68, 'OK', '2026-10-14 14:16:00'),
(3, 'wangjg', 'Meter', 'save', 'POST /api/meter', '', '127.0.0.1', 75, 'OK', '2026-10-15 15:20:00'),
(2, 'zhangli', 'Reading', 'submit', 'POST /api/reading/submit', '', '127.0.0.1', 82, 'OK', '2026-10-16 16:24:00'),
(3, 'wangjg', 'Bill', 'generate', 'POST /api/bill/generate', '', '127.0.0.1', 89, 'OK', '2026-10-17 17:28:00'),
(2, 'zhangli', 'Baseline', 'evaluate', 'POST /api/baseline/evaluate', '', '127.0.0.1', 96, 'OK', '2026-10-18 10:32:00'),
(3, 'wangjg', 'Exception', 'handle', 'POST /api/exception/1/handle', '', '127.0.0.1', 103, 'OK', '2026-10-19 11:36:00'),
(2, 'zhangli', 'Meter', 'save', 'POST /api/meter', '', '127.0.0.1', 110, 'OK', '2026-10-20 12:40:00'),
(3, 'wangjg', 'Reading', 'submit', 'POST /api/reading/submit', '', '127.0.0.1', 117, 'OK', '2026-10-21 13:44:00');

-- 数据规模自检
-- meter=22, reading_task=71, meter_reading=61, energy_bill=16, energy_exception=12, baseline_score=36, saving_measure=8
SET FOREIGN_KEY_CHECKS = 1;
