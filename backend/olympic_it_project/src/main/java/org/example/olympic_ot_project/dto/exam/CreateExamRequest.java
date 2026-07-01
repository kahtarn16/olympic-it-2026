package org.example.olympic_ot_project.dto.exam;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateExamRequest {
    @NotBlank(message = "Tên cuộc thi không được để trống")
    private String name;
    @NotNull(message = "Người ra đề không được để trống")
    private Integer createdById;
    private boolean shuffleOption;
}
