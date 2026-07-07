package org.example.olympic_ot_project.dto.student;

import lombok.Builder;
import lombok.Data;
import org.example.olympic_ot_project.dto.exam.websocket.QuestionDetailDto;

import java.time.LocalDateTime;

@Data
@Builder
public class ExamSessionDto {
    private String state;
    private Integer currentQuestionIndex;
    private Integer totalQuestions;
    private QuestionDetailDto currentQuestion;
    private Integer questionDuration;
    private LocalDateTime endAt;
    private Long remainingSeconds;
    private LocalDateTime currentQuestionStartedAt;
    private LocalDateTime currentQuestionEndAt;
}
