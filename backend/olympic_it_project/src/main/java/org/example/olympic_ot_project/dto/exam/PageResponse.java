package org.example.olympic_ot_project.dto.exam;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.List;

@Data
@AllArgsConstructor
public class PageResponse<T> {
    private List<T> data;
    private long totalElements;
    private int totalPages;
    private int page;
    private int size;
}