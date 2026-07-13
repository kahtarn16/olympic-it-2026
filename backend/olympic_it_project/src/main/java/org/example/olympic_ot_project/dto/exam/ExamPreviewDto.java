package org.example.olympic_ot_project.dto.exam;

import lombok.Builder;
import lombok.Data;
import org.example.olympic_ot_project.core.QuestionLevel;
import org.example.olympic_ot_project.core.QuestionType;

@Data
@Builder
public class ExamPreviewDto {
    private int index;
    private int totalQuestions;
    private int duration;
    private QuestionType type;
    private QuestionLevel level;
    private Integer score;
    private String category;
}