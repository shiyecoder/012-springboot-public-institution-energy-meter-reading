package com.grad.energy.controller;

import com.grad.energy.common.R;
import com.grad.energy.dto.Requests;
import com.grad.energy.service.ReadingService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

/** 抄表任务、抄表记录、异常单、Excel 导入。 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class ReadingController {

    private final ReadingService readingService;

    @GetMapping("/task/page")
    public R<Object> taskPage(@RequestParam Map<String, String> q) {
        return R.ok(readingService.taskPage(q));
    }

    @PostMapping("/task/generate")
    public R<Integer> generate(@RequestBody Requests.PlanGen req) {
        return R.ok(readingService.generatePlan(req.getPeriod(), req.getBuildingId()));
    }

    @PostMapping("/task/{id}/assign")
    public R<Void> assign(@PathVariable Long id, @RequestParam Long readerId) {
        readingService.assign(id, readerId);
        return R.ok();
    }

    @GetMapping("/reading/page")
    public R<Object> readingPage(@RequestParam Map<String, String> q) {
        return R.ok(readingService.readingPage(q));
    }

    @PostMapping("/reading/submit")
    public R<Map<String, Object>> submit(@RequestBody Requests.ReadingSubmit req) {
        return R.ok(readingService.submit(req));
    }

    @PostMapping("/reading/{id}/review")
    public R<Void> review(@PathVariable Long id, @RequestBody Requests.Review req) {
        readingService.review(id, req.getAction(), req.getNote());
        return R.ok();
    }

    @PostMapping("/reading/import")
    public R<Map<String, Object>> importExcel(@RequestParam("file") MultipartFile file,
                                              @RequestParam String period) {
        return R.ok(readingService.importExcel(file, period));
    }

    @GetMapping("/exception/page")
    public R<Object> exceptionPage(@RequestParam Map<String, String> q) {
        return R.ok(readingService.exceptionPage(q));
    }

    @PostMapping("/exception/{id}/handle")
    public R<Void> handle(@PathVariable Long id, @RequestBody Requests.ExceptionHandle req) {
        readingService.handleException(id, req);
        return R.ok();
    }
}
