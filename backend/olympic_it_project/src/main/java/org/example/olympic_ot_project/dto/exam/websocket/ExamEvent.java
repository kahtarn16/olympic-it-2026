package org.example.olympic_ot_project.dto.exam.websocket;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.example.olympic_ot_project.core.QuestionLevel;
import org.example.olympic_ot_project.core.QuestionType;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ExamEvent {
    private String type;
    private Integer currentQuestionIndex;
    private Integer totalQuestions;
    private Integer duration;
    private QuestionType questionType;
    private QuestionLevel questionLevel;
    private QuestionDetailDto questionData;
}
