package org.example.olympic_ot_project.dto.exam;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.example.olympic_ot_project.dto.exam.question.QuestionDetailResponse;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ExamQuestionResponse {
    private Integer orderIndex;
    private QuestionDetailResponse question;
}
