package org.example.olympic_ot_project.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.ApiResponse;
import org.example.olympic_ot_project.dto.exam.*;
import org.example.olympic_ot_project.dto.exam.question.RemoveQuestionRequest;
import org.example.olympic_ot_project.enity.Exam;
import org.example.olympic_ot_project.enity.ExamParticipant;
import org.example.olympic_ot_project.enity.ExamQuestion;
import org.example.olympic_ot_project.service.exam.ExamService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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

    @PutMapping("/{examId}")
    public ResponseEntity<ApiResponse<String>> update(
            @PathVariable Integer examId,
            @Valid @RequestBody UpdateExamRequest request
    ) {
        examService.updateExam(examId, request);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật đề thi thành công"));
    }

    @DeleteMapping("/{examId}")
    public ResponseEntity<ApiResponse<String>> delete(@PathVariable Integer examId) {
        examService.deleteExam(examId);
        return ResponseEntity.ok(ApiResponse.success("Xóa đề thi thành công"));
    }

    @PostMapping("/participant")
    public ResponseEntity<ApiResponse<String>> addParticipant(
            @Valid @RequestBody AddParticipantRequest request
    ) {
        examService.addParticipant(request);
        return ResponseEntity.ok(ApiResponse.success("Thêm thí sinh vào đề thành công"));
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
    public ResponseEntity<ApiResponse<DetailsExamResponse>> getDetail(@PathVariable Integer examId) {
        return ResponseEntity.ok(ApiResponse.success(examService.getExamDetail(examId)));
    }

    @GetMapping("/{examId}/questions")
    public ResponseEntity<ApiResponse<List<ExamQuestion>>> getExamQuestions(
            @PathVariable Integer examId
    ) {
        return ResponseEntity.ok(ApiResponse.success(examService.getExamQuestions(examId)));
    }

    @GetMapping("/{examId}/participants")
    public ResponseEntity<ApiResponse<List<ExamParticipantResponse>>> getExamParticipants(
            @PathVariable Integer examId
    ) {
        return ResponseEntity.ok(
                ApiResponse.success(examService.getExamParticipants(examId))
        );
    }

    @PostMapping("/validate-join")
    public ResponseEntity<ApiResponse<String>> validateJoin(
            @Valid @RequestBody ValidateJoinRequest request
    ) {
        examService.validateUserCanJoin(request);
        return ResponseEntity.ok(ApiResponse.success("Được vào phòng thi"));
    }

    @DeleteMapping("/participant")
    public ResponseEntity<ApiResponse<String>> removeParticipant(
            @RequestParam Integer examId,
            @RequestParam Integer userId
    ) {
        examService.removeParticipant(examId, userId);
        return ResponseEntity.ok(ApiResponse.success("Xóa thí sinh khỏi đề thi thành công"));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ExamListResponse>>> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String keyword
    ) {
        return ResponseEntity.ok(
                ApiResponse.success(examService.getAllExams(page, size, keyword))
        );
    }
}
