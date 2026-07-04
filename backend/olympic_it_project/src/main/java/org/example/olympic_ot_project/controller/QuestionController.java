package org.example.olympic_ot_project.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.ApiResponse;
import org.example.olympic_ot_project.dto.exam.option.CreateQuestionOptionRequest;
import org.example.olympic_ot_project.dto.exam.option.UpdateQuestionOptionRequest;
import org.example.olympic_ot_project.dto.exam.question.CreateQuestionRequest;
import org.example.olympic_ot_project.dto.exam.question.QuestionDetailResponse;
import org.example.olympic_ot_project.dto.exam.question.QuestionPageResponse;
import org.example.olympic_ot_project.dto.exam.question.UpdateQuestionRequest;
import org.example.olympic_ot_project.enity.Question;
import org.example.olympic_ot_project.service.exam.QuestionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/question")
@RequiredArgsConstructor
public class QuestionController {

    private final QuestionService questionService;

    @PostMapping
    public ResponseEntity<ApiResponse<String>> create(
            @Valid @RequestBody CreateQuestionRequest request
    ) {
        questionService.create(request);
        return ResponseEntity.ok(ApiResponse.success("Tạo câu hỏi thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> update(
            @PathVariable Integer id,
            @Valid @RequestBody UpdateQuestionRequest request
    ) {
        questionService.update(id, request);
        return ResponseEntity.ok(ApiResponse.success("Chỉnh sửa câu hỏi thành công"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> delete(
            @PathVariable Integer id
    ) {
        questionService.delete(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa câu hỏi thành công"));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<QuestionPageResponse>> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) Integer categoryId
    ) {
        return ResponseEntity.ok(
                ApiResponse.success(questionService.getAll(page, size, categoryId))
        );
    }

    @PostMapping("/{questionId}/option")
    public ResponseEntity<ApiResponse<String>> addOption(
            @PathVariable Integer questionId,
            @RequestBody @Valid CreateQuestionOptionRequest request
    ) {
        questionService.createOption(questionId, request);
        return ResponseEntity.ok(ApiResponse.success("Thêm đáp án thành công"));
    }

    @PutMapping("/option/{id}")
    public ResponseEntity<ApiResponse<String>> updateOption(
            @PathVariable Integer id,
            @RequestBody @Valid UpdateQuestionOptionRequest request
    ) {
        questionService.updateOption(id, request);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật đáp án thành công"));
    }

    @DeleteMapping("/option/{id}")
    public ResponseEntity<ApiResponse<String>> deleteOption(
            @PathVariable Integer id
    ) {
        questionService.deleteOption(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa đáp án thành công"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<QuestionDetailResponse>> getDetail(
            @PathVariable Integer id
    ) {
        return ResponseEntity.ok(
                ApiResponse.success(questionService.getDetail(id))
        );
    }
}