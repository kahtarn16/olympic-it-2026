package org.example.olympic_ot_project.dto.student;

import lombok.Builder;
import lombok.Data;
import org.example.olympic_ot_project.dto.exam.Leaderboard;

import java.util.List;

@Builder
@Data
public class StudentExamResultResponse {
    private Integer score;
    private Integer rank;
    private Integer totalParticipants;
    private List<Leaderboard> leaderboard;
}