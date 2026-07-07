package org.example.olympic_ot_project.dto.exam.websocket;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.example.olympic_ot_project.core.QuestionLevel;
import org.example.olympic_ot_project.core.QuestionType;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class QuestionDetailDto {
    private Integer id;
    private String content;
    private QuestionType type;
    private QuestionLevel level;
    private Integer score;
    private String imageUrl;
    private String videoUrl;
    private Integer timeLimit;
    private List<OptionDto> options;
}
