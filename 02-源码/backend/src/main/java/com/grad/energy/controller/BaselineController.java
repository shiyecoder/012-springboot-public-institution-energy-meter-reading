package com.grad.energy.controller;

import com.grad.energy.common.R;
import com.grad.energy.dto.Requests;
import com.grad.energy.service.BaselineService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** 创新点：能耗基线偏差识别（规则配置、计算、留痕、人工修正）。 */
@RestController
@RequestMapping("/api/baseline")
@RequiredArgsConstructor
public class BaselineController {

    private final BaselineService baselineService;

    @GetMapping("/rule")
    public R<Map<String, Object>> rule() {
        return R.ok(baselineService.currentRule());
    }

    @PostMapping("/rule")
    public R<Map<String, Object>> saveRule(@RequestBody Requests.RuleSave req) {
        return R.ok(baselineService.saveRule(req));
    }

    @PostMapping("/evaluate")
    public R<Map<String, Object>> evaluate(@RequestBody Requests.EvaluateReq req) {
        return R.ok(baselineService.evaluate(req));
    }

    @GetMapping("/page")
    public R<Object> page(@RequestParam Map<String, String> q) {
        return R.ok(baselineService.page(q));
    }

    @PostMapping("/{id}/adjust")
    public R<Void> adjust(@PathVariable Long id, @RequestBody Requests.ScoreAdjust req) {
        baselineService.adjust(id, req.getLevel(), req.getReason());
        return R.ok();
    }

    @GetMapping("/stat")
    public R<Map<String, Object>> stat() {
        return R.ok(baselineService.stat());
    }
}
