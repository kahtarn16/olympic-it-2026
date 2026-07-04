package org.example.olympic_ot_project.dto.exam.question;

import jakarta.validation.constraints.*;
import lombok.Data;
import org.example.olympic_ot_project.core.QuestionLevel;
import org.example.olympic_ot_project.core.QuestionType;
import org.example.olympic_ot_project.dto.exam.option.CreateQuestionOptionRequest;

import java.util.List;

@Data
public class CreateQuestionRequest {
    @NotBlank(message = "Nội dung không được để trống")
    private String content;

    @NotNull(message = "Loại câu hỏi không được để trống")
    private QuestionType type;

    @NotNull(message = "Cấp độ câu hỏi không được để trống")
    private QuestionLevel level;

    private String answer;

    @NotNull(message = "Điểm số câu hỏi không được để trống")
    private Integer score;

    @NotNull(message = "Loại câu hỏi không được để trống")
    private Integer categoryId;

    @NotNull(message = "Thời gian trả lời không được bỏ trống")
    @Min(value = 30, message = "Thời gian thấp nhất là 30 giây")
    @Max(value = 120, message = "Thời gian cao nhất là 120 giây")
    private Integer timeLimit;

    private String imageUrl;
    private String videoUrl;

    private List<CreateQuestionOptionRequest> options;
}
