package org.example.olympic_ot_project.dto.exam.anticheat;

import lombok.Builder;
import lombok.Data;
import org.example.olympic_ot_project.core.AntiCheatType;

import java.time.LocalDateTime;

@Builder
@Data
public class AntiCheatResponse {
    private Integer userId;
    private String fullName;
    private AntiCheatType type;
    private LocalDateTime createdAt;
}