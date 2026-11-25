package com.grad.energy.controller;

import com.grad.energy.common.R;
import com.grad.energy.dto.Requests;
import com.grad.energy.service.AnalysisService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** 统计看板、能耗定额、节能措施。 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class AnalysisController {

    private final AnalysisService analysisService;

    @GetMapping("/dashboard")
    public R<Map<String, Object>> dashboard(@RequestParam(required = false) String period) {
        return R.ok(analysisService.dashboard(period));
    }

    @GetMapping("/quota/page")
    public R<Object> quotaPage(@RequestParam Map<String, String> q) {
        return R.ok(analysisService.quotaPage(q));
    }

    @PostMapping("/quota/save")
    public R<Void> saveQuota(@RequestBody Requests.QuotaSave req) {
        analysisService.saveQuota(req);
        return R.ok();
    }

    @GetMapping("/measure/page")
    public R<Object> measurePage(@RequestParam Map<String, String> q) {
        return R.ok(analysisService.measurePage(q));
    }

    @PostMapping("/measure/save")
    public R<Void> saveMeasure(@RequestBody Requests.MeasureSave req) {
        analysisService.saveMeasure(req);
        return R.ok();
    }
}
