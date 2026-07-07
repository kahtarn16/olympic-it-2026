package org.example.olympic_ot_project.dto.student;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class JoinRoomResponse {
    private Integer examId;
    private String examName;
    private String state;
    private String message;
}
