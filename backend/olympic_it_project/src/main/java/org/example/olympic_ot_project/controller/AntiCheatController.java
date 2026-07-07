package org.example.olympic_ot_project.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.ApiResponse;
import org.example.olympic_ot_project.dto.exam.anticheat.AntiCheatRequest;
import org.example.olympic_ot_project.dto.exam.anticheat.AntiCheatResponse;
import org.example.olympic_ot_project.service.exam.AntiCheatService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/exam/anti-cheat")
@RequiredArgsConstructor
public class AntiCheatController {

    private final AntiCheatService antiCheatService;

    @PostMapping
    public ApiResponse<Void> recordViolation(
            @RequestBody @Valid AntiCheatRequest request) {

        antiCheatService.recordViolation(request);

        return ApiResponse.<Void>builder()
                .message("Violation recorded")
                .build();
    }

    @GetMapping("/{examId}")
    public ApiResponse<List<AntiCheatResponse>> getViolations(
            @PathVariable Integer examId) {

        return ApiResponse.<List<AntiCheatResponse>>builder()
                .data(antiCheatService.getViolations(examId))
                .build();
    }
}