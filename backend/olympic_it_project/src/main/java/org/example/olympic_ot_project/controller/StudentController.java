package org.example.olympic_ot_project.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.ApiResponse;
import org.example.olympic_ot_project.dto.student.CreateStudentRequest;
import org.example.olympic_ot_project.dto.student.StudentResponse;
import org.example.olympic_ot_project.dto.student.UpdateStudentRequest;
import org.example.olympic_ot_project.service.student.StudentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("api/admin/student")
@RequiredArgsConstructor
public class StudentController {
    private final StudentService studentService;

    @PostMapping
    public ResponseEntity<ApiResponse<String>> create(@Valid @RequestBody CreateStudentRequest request) {
        studentService.createStudent(request);
        return ResponseEntity.ok(ApiResponse.success("Tạo sinh viên thành công"));
    }

    @GetMapping
    public ApiResponse<List<StudentResponse>> getAll(
            @RequestParam(required = false) Integer academicYearId,
            @RequestParam(required = false) Integer classId
    ){
        return ApiResponse.<List<StudentResponse>>builder()
                .data(studentService.getAllStudents(academicYearId, classId))
                .build();
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> update(@PathVariable Integer id, @Valid @RequestBody UpdateStudentRequest request) {
        studentService.updateStudent(id, request);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật sinh viên thành công"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> delete(@PathVariable Integer id) {
        studentService.deleteStudent(id);
        return ResponseEntity.ok(ApiResponse.success("Khóa sinh viên thành công"));
    }

    @PutMapping("/{id}/unlock")
    public ResponseEntity<ApiResponse<String>> unlock(@PathVariable Integer id) {
        studentService.unlockStudent(id);
        return ResponseEntity.ok(ApiResponse.success("Mở khóa sinh viên thành công"));
    }
}
