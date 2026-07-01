package org.example.olympic_ot_project.dto.exam.question;

import lombok.Data;
import org.example.olympic_ot_project.Core.QuestionLevel;
import org.example.olympic_ot_project.Core.QuestionType;
import org.example.olympic_ot_project.dto.exam.option.QuestionOptionResponse;

import java.util.List;

@Data
public class QuestionDetailResponse {

    private Integer id;
    private String content;

    private QuestionType type;
    private QuestionLevel level;

    private Integer categoryId;
    private String categoryName;

    private List<QuestionOptionResponse> options;
}