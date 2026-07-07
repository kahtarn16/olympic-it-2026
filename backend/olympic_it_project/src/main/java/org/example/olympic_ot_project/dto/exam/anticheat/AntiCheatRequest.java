package org.example.olympic_ot_project.dto.exam.anticheat;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import org.example.olympic_ot_project.core.AntiCheatType;

@Data
public class AntiCheatRequest {
    private Integer examId;
    private AntiCheatType type;
}