package org.example.olympic_ot_project.dto.exam;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ExamListResponse {
    private Integer id;
    private String name;
    private String status;
    private boolean shuffleOption;
    private String createdBy;
    private String createdAt;
}