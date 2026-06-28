package org.example.olympic_ot_project.dto.academicyear;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreateAcademicYearRequest {
    @NotBlank(message = "Tên khóa không được để trống")
    private String academicYearName;
}
