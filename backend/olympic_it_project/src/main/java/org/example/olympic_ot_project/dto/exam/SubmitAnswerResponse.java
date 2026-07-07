package org.example.olympic_ot_project.dto.exam;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class SubmitAnswerResponse {
    private Integer questionIndex;
    private Boolean isCorrect;
    private Integer currentScore;
}
