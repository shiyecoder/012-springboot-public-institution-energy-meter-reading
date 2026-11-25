package com.grad.energy.controller;

import com.grad.energy.common.R;
import com.grad.energy.dto.Requests;
import com.grad.energy.entity.TariffRule;
import com.grad.energy.service.BillService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** 费用台账与计费规则。 */
@RestController
@RequestMapping("/api/bill")
@RequiredArgsConstructor
public class BillController {

    private final BillService billService;

    @GetMapping("/page")
    public R<Object> page(@RequestParam Map<String, String> q) {
        return R.ok(billService.page(q));
    }

    @PostMapping("/generate")
    public R<Map<String, Object>> generate(@RequestParam String period) {
        return R.ok(billService.generate(period));
    }

    @PostMapping("/{id}/adjust")
    public R<Void> adjust(@PathVariable Long id, @RequestBody Requests.BillAdjust req) {
        billService.adjust(id, req.getAdjustAmount(), req.getReason());
        return R.ok();
    }

    @GetMapping("/tariffs")
    public R<List<TariffRule>> tariffs() {
        return R.ok(billService.tariffs());
    }
}
