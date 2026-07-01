package org.example.olympic_ot_project.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.ApiResponse;
import org.example.olympic_ot_project.dto.classes.ClassResponse;
import org.example.olympic_ot_project.dto.classes.CreateClassRequest;
import org.example.olympic_ot_project.dto.classes.UpdateClassRequest;
import org.example.olympic_ot_project.service.classes.ClassesService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("api/admin/classes")
@RequiredArgsConstructor
public class ClassesController {
    private final ClassesService classesService;

    @PostMapping()
    public ResponseEntity<ApiResponse<String>> create(@Valid @RequestBody CreateClassRequest request) {
        classesService.createClasses(request);
        return ResponseEntity.ok(ApiResponse.success("Thêm lớp thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> update(@PathVariable Integer id, @Valid @RequestBody UpdateClassRequest request) {
        classesService.updateClasses(id, request);
        return ResponseEntity.ok(ApiResponse.success("Chỉnh sửa lớp thành công"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> delete(@PathVariable Integer id) {
        classesService.delete(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa lớp thành công"));
    }

    @GetMapping()
    public ResponseEntity<ApiResponse<List<ClassResponse>>> getAll(
            @RequestParam(required = false) Integer academicYearId
    ) {
        List<ClassResponse> data = classesService.getByAcademicYear(academicYearId);
        return ResponseEntity.ok(ApiResponse.success(data));
    }
}
