package org.example.olympic_ot_project.dto.exam.option;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import org.example.olympic_ot_project.enity.Question;
import org.example.olympic_ot_project.enity.QuestionOption;

@Data
public class CreateQuestionOptionRequest {
    @NotNull(message = "Ký hiệu đáp án không được để trống")
    private Character label;

    @NotBlank(message = "Nội dung câu hỏi không được để trống")
    private String contentText;

    private String imageUrl;

    private Boolean isCorrect;

    public QuestionOption toEntity(Question question) {
        QuestionOption entity = new QuestionOption();
        entity.setLabel(this.label);
        entity.setContentText(this.contentText);
        entity.setImageUrl(this.imageUrl);
        entity.setIsCorrect(this.isCorrect != null ? this.isCorrect : false);
        entity.setQuestion(question);
        return entity;
    }
}