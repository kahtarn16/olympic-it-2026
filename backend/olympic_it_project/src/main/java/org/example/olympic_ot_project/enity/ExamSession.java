package org.example.olympic_ot_project.enity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.example.olympic_ot_project.core.ExamState;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "exam_session")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExamSession {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @OneToOne
    @JoinColumn(name = "exam_id", nullable = false)
    private Exam exam;

    private Integer currentQuestionIndex;

    @Enumerated(EnumType.STRING)
    private ExamState state;

    private Integer questionDuration;
    private LocalDateTime currentQuestionStartedAt;
    private LocalDateTime currentQuestionEndAt;
    private Boolean shuffleMode;

    private boolean locked = false;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
