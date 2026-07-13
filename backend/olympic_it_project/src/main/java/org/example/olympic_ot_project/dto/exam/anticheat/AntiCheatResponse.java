package org.example.olympic_ot_project.dto.exam.anticheat;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.example.olympic_ot_project.core.AntiCheatType;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AntiCheatResponse {
    private Integer userId;
    private String fullName;
    private AntiCheatType type;
    private LocalDateTime createdAt;
    private Integer violationCount;
    private boolean banned;
}