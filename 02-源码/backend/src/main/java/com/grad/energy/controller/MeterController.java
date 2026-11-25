package com.grad.energy.controller;

import com.grad.energy.common.R;
import com.grad.energy.entity.Building;
import com.grad.energy.entity.EnergyUnit;
import com.grad.energy.entity.Meter;
import com.grad.energy.service.MeterService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** 表计资产台账、建筑与用能单元台账。 */
@RestController
@RequestMapping("/api/meter")
@RequiredArgsConstructor
public class MeterController {

    private final MeterService meterService;

    @GetMapping("/page")
    public R<Object> page(@RequestParam Map<String, String> q) {
        return R.ok(meterService.page(q));
    }

    @GetMapping("/{id}")
    public R<Map<String, Object>> detail(@PathVariable Long id) {
        return R.ok(meterService.detail(id));
    }

    @PostMapping
    public R<Long> save(@RequestBody Meter meter) {
        return R.ok(meterService.save(meter));
    }

    @PutMapping("/{id}")
    public R<Void> update(@PathVariable Long id, @RequestBody Meter meter) {
        meter.setId(id);
        meterService.update(meter);
        return R.ok();
    }

    @DeleteMapping("/{id}")
    public R<Void> delete(@PathVariable Long id) {
        meterService.delete(id);
        return R.ok();
    }

    @PostMapping("/{id}/status")
    public R<Void> status(@PathVariable Long id, @RequestParam String status) {
        meterService.changeStatus(id, status);
        return R.ok();
    }

    @GetMapping("/buildings")
    public R<List<Building>> buildings() {
        return R.ok(meterService.buildings());
    }

    @GetMapping("/units")
    public R<List<EnergyUnit>> units(@RequestParam(required = false) Long buildingId) {
        return R.ok(meterService.units(buildingId));
    }
}
