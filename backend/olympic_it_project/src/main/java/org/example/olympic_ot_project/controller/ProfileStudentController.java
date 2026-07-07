package org.example.olympic_ot_project.controller;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.ApiResponse;
import org.example.olympic_ot_project.dto.student.MyExamResponse;
import org.example.olympic_ot_project.dto.student.StudentMeResponse;
import org.example.olympic_ot_project.service.auth.CustomUserDetailsService;
import org.example.olympic_ot_project.service.student.ProfileStudentService;
import org.example.olympic_ot_project.service.student.StudentService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/profile")
@RequiredArgsConstructor
public class ProfileStudentController {

    private final ProfileStudentService profileStudentService;

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<StudentMeResponse>> getMe() {

        String username =
                SecurityContextHolder.getContext().getAuthentication().getName();

        StudentMeResponse data =
                profileStudentService.getMe(username);

        return ResponseEntity.ok(ApiResponse.success(data));
    }

    @GetMapping("/my-exams")
    public ResponseEntity<ApiResponse<List<MyExamResponse>>> myExams() {

        String username =
                SecurityContextHolder.getContext().getAuthentication().getName();

        List<MyExamResponse> data =
                profileStudentService.getMyExams(username);

        return ResponseEntity.ok(ApiResponse.success(data));
    }
}