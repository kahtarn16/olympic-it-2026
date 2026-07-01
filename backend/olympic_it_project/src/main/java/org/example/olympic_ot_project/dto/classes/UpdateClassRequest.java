package org.example.olympic_ot_project.dto.classes;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdateClassRequest {
    @NotBlank(message = "Tên lớp không được để trống")
    private String className;
    @NotNull(message = "Năm học không được để trống")
    private Integer academicYearId;
}
