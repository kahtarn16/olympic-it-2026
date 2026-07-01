package org.example.olympic_ot_project.dto.exam.question;

import lombok.Data;

import java.util.List;

@Data
public class QuestionPageResponse {

    private List<QuestionResponse> items;

    private int page;
    private int size;
    private long totalElements;
    private int totalPages;
}
