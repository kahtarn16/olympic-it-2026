package org.example.olympic_ot_project.dto.exam;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class AddParticipantRequest {
    @NotNull(message = "Id đề thi không được để trống")
    private Integer examId;

    @NotNull(message = "Id thí sinh không được để trống")
    private Integer userId;

    @NotNull(message = "Số ngồi đại diện không được để trống")
    private Integer seatNumber;
}