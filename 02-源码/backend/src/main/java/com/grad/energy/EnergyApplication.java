package com.grad.energy;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 公共机构能耗抄表与节能分析系统启动类。
 * 端口 8081（通道 2），数据库 new_012。
 */
@SpringBootApplication
@MapperScan("com.grad.energy.mapper")
public class EnergyApplication {
    public static void main(String[] args) {
        SpringApplication.run(EnergyApplication.class, args);
    }
}
