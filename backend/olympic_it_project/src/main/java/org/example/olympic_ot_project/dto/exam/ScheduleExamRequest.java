package org.example.olympic_ot_project.dto.exam;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class ScheduleExamRequest {
    private LocalDateTime startAt;
}