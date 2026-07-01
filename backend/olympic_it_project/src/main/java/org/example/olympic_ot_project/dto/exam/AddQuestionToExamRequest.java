package org.example.olympic_ot_project.dto.exam;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class AddQuestionToExamRequest {
    @NotNull(message = "Id cuộc thi không được bỏ trống")
    private Integer examId;

    @NotNull(message = "Id câu hỏi không được bỏ trống")
    private Integer questionId;

    @NotNull(message = "Id số thứ tự không được bỏ trống")
    private Integer orderIndex;
}
