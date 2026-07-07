package org.example.olympic_ot_project.enity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "exam_participant_progress")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExamParticipantProgress {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "exam_id")
    private Exam exam;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private Users user;

    private Integer questionIndex;
    private Integer selectedOptionId;

    @Column(columnDefinition = "TEXT")
    private String answerText;

    private Boolean isCorrect;
    private LocalDateTime answeredAt;
}
