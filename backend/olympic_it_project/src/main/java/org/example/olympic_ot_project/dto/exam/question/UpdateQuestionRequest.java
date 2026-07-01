package org.example.olympic_ot_project.dto.exam;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import org.example.olympic_ot_project.Core.QuestionLevel;
import org.example.olympic_ot_project.Core.QuestionType;

@Data
public class UpdateQuestionRequest {
    @NotNull(message = "Id câu hỏi không được để trống")
    private Integer id;

    @NotBlank
    private String content;

    @NotNull(message = "Loại câu hỏi không được để trống")
    private QuestionType type;

    @NotNull(message = "Cấp bậc câu hỏi không được để trống")
    private QuestionLevel level;

    private String imageUrl;
    private String videoUrl;
}
