package org.example.olympic_ot_project.dto.student;

import lombok.Data;

@Data
public class StudentResponse {
    private Integer id;
    private String username;
    private String email;
    private String fullName;
    private String className;
    private Integer classId;
}
