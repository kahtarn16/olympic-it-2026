package org.example.olympic_ot_project.dto.exam;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.example.olympic_ot_project.dto.exam.question.QuestionResponse;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DetailsExamResponse {

    private Integer id;
    private String name;
    private String status;
    private LocalDateTime scheduledStartAt;
    private String createdBy;
    private String createdAt;

    private List<ExamQuestionResponse> questions;

    private List<ExamParticipantResponse> participants;
}