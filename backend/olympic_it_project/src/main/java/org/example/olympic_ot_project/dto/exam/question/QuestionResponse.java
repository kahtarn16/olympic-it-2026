package org.example.olympic_ot_project.dto.exam.question;

import lombok.Data;
import org.example.olympic_ot_project.core.QuestionLevel;
import org.example.olympic_ot_project.core.QuestionType;

@Data
public class QuestionResponse {
    private Integer id;
    private String content;
    private QuestionType type;
    private QuestionLevel level;
    private Integer score;
    private Integer timeLimit;
    private String imageUrl;
    private String videoUrl;
    private Integer categoryId;
    private String categoryName;
    private Integer orderIndex;
}
