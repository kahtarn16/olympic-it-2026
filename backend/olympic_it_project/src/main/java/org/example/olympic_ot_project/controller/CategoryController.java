package org.example.olympic_ot_project.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.ApiResponse;
import org.example.olympic_ot_project.dto.exam.category.CategoryResponse;
import org.example.olympic_ot_project.dto.exam.category.CreateCategoryRequest;
import org.example.olympic_ot_project.dto.exam.category.UpdateCategoryRequest;
import org.example.olympic_ot_project.service.category.CategoryService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/category")
@RequiredArgsConstructor
public class CategoryController {

    private final CategoryService categoryService;

    @PostMapping
    public ResponseEntity<ApiResponse<String>> create(
            @RequestBody @Valid CreateCategoryRequest request
    ) {
        categoryService.create(request);
        return ResponseEntity.ok(
                ApiResponse.success("Tạo category thành công")
        );
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> update(
            @PathVariable Integer id,
            @RequestBody @Valid UpdateCategoryRequest request
    ) {
        categoryService.update(id, request);
        return ResponseEntity.ok(
                ApiResponse.success("Cập nhật category thành công")
        );
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> delete(
            @PathVariable Integer id
    ) {
        categoryService.delete(id);
        return ResponseEntity.ok(
                ApiResponse.success("Xóa category thành công")
        );
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<CategoryResponse>>> getAll() {
        return ResponseEntity.ok(
                ApiResponse.success(categoryService.getAll())
        );
    }
}