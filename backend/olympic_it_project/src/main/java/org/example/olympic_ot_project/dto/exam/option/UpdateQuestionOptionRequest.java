package org.example.olympic_ot_project.dto.exam;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdateQuestionOptionRequest {
    @NotNull(message = "Id câu hỏi không được bỏ trống")
    private Integer optionId;

    @NotNull(message = "Ký hiệu đáp án không được để trống")
    private Character label;

    @NotBlank(message = "Nội dung câu hỏi không được để trống")
    private String contentText;

    private boolean isCorrect;
}
