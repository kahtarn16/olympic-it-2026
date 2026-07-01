package org.example.olympic_ot_project.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.ApiResponse;
import org.example.olympic_ot_project.dto.exam.AddQuestionToExamRequest;
import org.example.olympic_ot_project.dto.exam.CreateExamRequest;
import org.example.olympic_ot_project.dto.exam.question.RemoveQuestionRequest;
import org.example.olympic_ot_project.dto.exam.ValidateJoinRequest;
import org.example.olympic_ot_project.enity.Exam;
import org.example.olympic_ot_project.service.exam.ExamService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/exam")
@RequiredArgsConstructor
public class ExamController {
    private final ExamService examService;

    @PostMapping
    public ResponseEntity<ApiResponse<String>> create(@Valid @RequestBody CreateExamRequest request) {
        examService.createExam(request);
        return ResponseEntity.ok(ApiResponse.success("Tạo đề thi thành công"));
    }

    @PostMapping("/question")
    public ResponseEntity<ApiResponse<String>> addQuestion(
            @Valid @RequestBody AddQuestionToExamRequest request
    ) {
        examService.addQuestion(request);
        return ResponseEntity.ok(ApiResponse.success("Thêm câu hỏi vào đề thành công"));
    }

    @DeleteMapping("/question")
    public ResponseEntity<ApiResponse<String>> removeQuestion(
            @Valid @RequestBody RemoveQuestionRequest request
    ) {
        examService.removeQuestion(request);
        return ResponseEntity.ok(ApiResponse.success("Xóa câu hỏi khỏi đề thành công"));
    }

    @PutMapping("/{examId}/start")
    public ResponseEntity<ApiResponse<String>> startExam(@PathVariable Integer examId) {
        examService.startExam(examId);
        return ResponseEntity.ok(ApiResponse.success("Bắt đầu cuộc thi"));
    }

    @GetMapping("/{examId}")
    public ResponseEntity<ApiResponse<Exam>> getDetail(@PathVariable Integer examId) {
        return ResponseEntity.ok(ApiResponse.success(examService.getExamDetail(examId)));
    }

    @PostMapping("/validate-join")
    public ResponseEntity<ApiResponse<String>> validateJoin(
            @Valid @RequestBody ValidateJoinRequest request
    ) {
        examService.validateUserCanJoin(request);
        return ResponseEntity.ok(ApiResponse.success("Được vào phòng thi"));
    }
}
