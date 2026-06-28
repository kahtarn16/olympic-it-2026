package org.example.olympic_ot_project.dto.academicyear;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UpdateAcademicYearRequest {
    @NotBlank(message = "Tên khóa không được để trống")
    private String academicYearName;
}
