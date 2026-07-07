package org.example.olympic_ot_project.dto.exam;

import lombok.Builder;
import lombok.Data;
import org.example.olympic_ot_project.core.QuestionLevel;
import org.example.olympic_ot_project.core.QuestionType;

@Data
@Builder
public class ExamPreviewDto {
    private Integer index;
    private Integer totalQuestions;
    private Integer duration;
    private QuestionType type;
    private QuestionLevel level;
    private Integer score;
}