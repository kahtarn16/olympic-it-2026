package org.example.olympic_ot_project.dto.student;

import lombok.Builder;
import lombok.Data;
import org.example.olympic_ot_project.core.ExamStatus;

@Data
@Builder
public class StudentExamDetailResponse {

    private Integer id;

    private String name;

    private ExamStatus status;

    private Integer totalQuestions;
}