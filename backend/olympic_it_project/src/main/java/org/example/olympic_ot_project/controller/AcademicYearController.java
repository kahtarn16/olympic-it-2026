package org.example.olympic_ot_project.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.ApiResponse;
import org.example.olympic_ot_project.dto.academicyear.AcademicYearResponse;
import org.example.olympic_ot_project.dto.academicyear.CreateAcademicYearRequest;
import org.example.olympic_ot_project.dto.academicyear.UpdateAcademicYearRequest;
import org.example.olympic_ot_project.service.academicyear.AcademicYearService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("api/admin/academic-year")
@RequiredArgsConstructor
public class AcademicYearController {
    final AcademicYearService academicYearService;

    @PostMapping("/create")
    public ResponseEntity<ApiResponse<String>> createAcademicYear(@Valid @RequestBody CreateAcademicYearRequest request) {
        academicYearService.createAcademicYear(request);
        return ResponseEntity.ok(ApiResponse.success("Thêm khóa học thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> updateAcademicYear(@Valid  @PathVariable Integer id, @RequestBody UpdateAcademicYearRequest request) {
        academicYearService.updateAcademicYear(id, request);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật khóa học thành công"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> delete(@PathVariable Integer id) {
        academicYearService.deleteAcademicYear(id);

        return ResponseEntity.ok(ApiResponse.success("Xóa khóa học thành công"));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<AcademicYearResponse>>> getAll() {
        List<AcademicYearResponse> data = academicYearService.getAll();

        return ResponseEntity.ok(ApiResponse.success(data));
    }
}
