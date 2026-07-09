package org.example.olympic_ot_project.dto.exam;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.example.olympic_ot_project.core.ExamState;

import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ExamSessionResponse {

    private String examName;

    private ExamState state;

    private Integer currentQuestionIndex;

    private Integer totalQuestions;

    private Integer totalParticipants;

    private Integer questionDuration;

    private LocalDateTime currentQuestionStartedAt;

    private LocalDateTime currentQuestionEndAt;

    private Boolean locked;
}
