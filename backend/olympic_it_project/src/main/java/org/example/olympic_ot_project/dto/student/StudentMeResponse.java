package org.example.olympic_ot_project.dto.student;

import lombok.Data;

@Data
public class StudentMeResponse {
    private Integer id;
    private String username;
    private String fullName;
    private String email;

    private String className;
    private String academicYear;
}