package org.example.olympic_ot_project.dto.exam.category;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreateCategoryRequest {
    @NotBlank(message = "Tên category không được để trống")
    private String name;
}
