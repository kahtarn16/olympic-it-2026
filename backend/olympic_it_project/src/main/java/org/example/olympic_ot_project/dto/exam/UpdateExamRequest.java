package org.example.olympic_ot_project.dto.exam;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UpdateExamRequest {
    @NotBlank(message = "Tên cuộc thi không được để trống")
    private String name;
    private boolean shuffleOption;
}
