package org.example.olympic_ot_project.dto.exam;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class GetExamDetailRequest {
    @NotNull(message = "Id cuộc thi không được để trống")
    private Integer examId;
}
