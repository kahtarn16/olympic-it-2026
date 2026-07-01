package org.example.olympic_ot_project.dto.exam;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class RemoveQuestionRequest {
    @NotNull(message = "Id cuộc thi không được bỏ trống")
    private Integer examId;
    @NotNull(message = "Id câu hỏi không được bỏ trống")
    private Integer questionId;
}