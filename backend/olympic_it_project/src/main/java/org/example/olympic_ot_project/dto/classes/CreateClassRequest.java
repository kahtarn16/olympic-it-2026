package org.example.olympic_ot_project.dto.classes;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreateClassRequest {
    @NotBlank(message = "Tên lớp không được để trống")
    private String className;
    @NotBlank(message = "Năm học không được để trống")
    private Integer academicYearId;
}
