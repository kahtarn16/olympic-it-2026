package org.example.olympic_ot_project.dto.exam;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ValidateJoinRequest {
    @NotNull(message = "Id cuộc thi không được bỏ trống")
    private Integer examId;

    @NotNull(message = "Id thí sinh không được bỏ trống")
    private Integer userId;
}
