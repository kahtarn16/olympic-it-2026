package org.example.olympic_ot_project.enity;

import jakarta.persistence.*;
import lombok.*;
import org.example.olympic_ot_project.Core.ParticipantStatus;

import java.time.LocalDateTime;

@Entity
@Table(name = "exam_participant",
        uniqueConstraints = @UniqueConstraint(columnNames = {"exam_id", "user_id"}))
@Getter
@Setter
public class ExamParticipant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "exam_id", nullable = false)
    private Exam exam;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private Users user;

    @Enumerated(EnumType.STRING)
    private ParticipantStatus status;

    private Integer score = 0;

    private LocalDateTime invitedAt = LocalDateTime.now();
}