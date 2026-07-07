package org.example.olympic_ot_project.dto.exam;

import lombok.Builder;
import lombok.Data;
import org.example.olympic_ot_project.dto.exam.websocket.QuestionDetailDto;

@Builder
@Data
public class ExamRestoreResponse {
    private String state;
    private Integer currentQuestionIndex;
    private Integer totalQuestions;

    private QuestionDetailDto currentQuestion;

    private Long remainingSeconds;
}