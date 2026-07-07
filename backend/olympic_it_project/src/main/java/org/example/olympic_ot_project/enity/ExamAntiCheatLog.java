package org.example.olympic_ot_project.enity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.example.olympic_ot_project.core.AntiCheatType;

import java.time.LocalDateTime;

@Entity
@Table(name = "exam_anti_cheat_log")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class ExamAntiCheatLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "exam_id")
    private Exam exam;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private Users user;

    @Enumerated(EnumType.STRING)
    private AntiCheatType type;

    private LocalDateTime createdAt;
}
