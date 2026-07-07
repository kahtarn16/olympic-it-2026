package org.example.olympic_ot_project.dto.student;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class ExamSession {
    private String state;
    private Integer currentQuestionIndex;
    private Integer totalQuestions;
    private Integer questionDuration;
    private LocalDateTime endAt;
}
