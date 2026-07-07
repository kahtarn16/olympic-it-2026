package org.example.olympic_ot_project.dto.exam;


import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Leaderboard {
    private Integer rank;
    private Integer userId;
    private String name;
    private Integer score;
}
