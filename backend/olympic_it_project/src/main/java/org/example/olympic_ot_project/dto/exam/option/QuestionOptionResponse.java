package org.example.olympic_ot_project.dto.exam.option;

import lombok.Data;

@Data
public class QuestionOptionResponse {
    private Integer id;
    private Character label;
    private String contentText;
    private boolean isCorrect;
}
