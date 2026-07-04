package org.example.olympic_ot_project.dto.exam.question;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;
import org.example.olympic_ot_project.core.QuestionLevel;
import org.example.olympic_ot_project.core.QuestionType;
import org.example.olympic_ot_project.dto.exam.option.CreateQuestionOptionRequest;

import java.util.List;

@Data
public class UpdateQuestionRequest {
    @NotBlank(message = "Nội dung không được để trống")
    private String content;

    @NotNull(message = "Loại câu hỏi không được để trống")
    private QuestionType type;

    @NotNull(message = "Cấp độ câu hỏi không được để trống")
    private QuestionLevel level;

    @NotNull(message = "Category không được để trống")
    private Integer categoryId;

    private String answer;

    @NotNull(message = "Điểm số câu hỏi không được để trống")
    private Integer score;

    @NotNull(message = "Thời gian trả lời không được bỏ trống")
    @Min(value = 30, message = "Thời gian phải có ít nhất 3- giây")
    private Integer timeLimit;

    private String imageUrl;
    private String videoUrl;
    private List<CreateQuestionOptionRequest> options;
}
