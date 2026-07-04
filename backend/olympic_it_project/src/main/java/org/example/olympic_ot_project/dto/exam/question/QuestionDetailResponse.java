package org.example.olympic_ot_project.dto.exam.question;

import lombok.Data;
import org.example.olympic_ot_project.core.QuestionLevel;
import org.example.olympic_ot_project.core.QuestionType;
import org.example.olympic_ot_project.dto.exam.option.QuestionOptionResponse;

import java.util.List;

@Data
public class QuestionDetailResponse {

    private Integer id;
    private String content;
    private String answer;
    private Integer score;
    private String imageUrl;
    private String videoUrl;
    private QuestionType type;
    private QuestionLevel level;
    private Integer timeLimit;
    private Integer categoryId;
    private String categoryName;

    private List<QuestionOptionResponse> options;
}