package org.example.olympic_ot_project.dto.exam;

import lombok.AllArgsConstructor;
import lombok.Data;
import org.example.olympic_ot_project.core.ParticipantStatus;


@Data
@AllArgsConstructor
public class ExamParticipantResponse {
    private Integer id;
    private Integer userId;
    private String fullName;
    private String className;
    private ParticipantStatus status;
    private Integer score;
    Integer seatNumber;
}
