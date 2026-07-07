package org.example.olympic_ot_project.dto.exam.websocket;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SubmitAnswerPayload {
    private Integer selectedOptionId;
    private String answerText;
}
