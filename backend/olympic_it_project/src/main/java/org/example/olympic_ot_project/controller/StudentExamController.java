package org.example.olympic_ot_project.controller;

import lombok.RequiredArgsConstructor;
import org.apache.tomcat.util.net.openssl.ciphers.Authentication;
import org.example.olympic_ot_project.dto.ApiResponse;
import org.example.olympic_ot_project.dto.student.ExamSessionDto;
import org.example.olympic_ot_project.dto.student.JoinRoomResponse;
import org.example.olympic_ot_project.dto.student.StudentExamDetailResponse;
import org.example.olympic_ot_project.dto.student.StudentExamResultResponse;
import org.example.olympic_ot_project.service.student.StudentExamService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/student/exam")
@RequiredArgsConstructor
public class StudentExamController {

    private final StudentExamService studentExamService;

    @PostMapping("/{examId}/join")
    public ResponseEntity<ApiResponse<JoinRoomResponse>> join(
            @PathVariable Integer examId
    ) {

        String username = SecurityContextHolder
                .getContext()
                .getAuthentication()
                .getName();

        JoinRoomResponse response =
                studentExamService.joinRoom(examId, username);

        return ResponseEntity.ok(
                ApiResponse.success(response)
        );
    }

    @GetMapping("/{examId}/session")
    public ResponseEntity<ApiResponse<ExamSessionDto>> session(
            @PathVariable Integer examId
    ) {

        ExamSessionDto response =
                studentExamService.getSession(examId);

        return ResponseEntity.ok(
                ApiResponse.success(response)
        );
    }

    @GetMapping("/{examId}")
    public ResponseEntity<ApiResponse<StudentExamDetailResponse>> getExamDetail(
            @PathVariable Integer examId
    ) {

        StudentExamDetailResponse response =
                studentExamService.getExamDetail(examId);

        return ResponseEntity.ok(
                ApiResponse.success(response)
        );
    }

    @GetMapping("/{examId}/result")
    public ResponseEntity<ApiResponse<StudentExamResultResponse>> result(
            @PathVariable Integer examId
    ) {

        StudentExamResultResponse response =
                studentExamService.getExamResult(examId);

        return ResponseEntity.ok(
                ApiResponse.success(response)
        );
    }
}