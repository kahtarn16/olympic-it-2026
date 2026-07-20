package org.example.olympic_ot_project.enity;

import jakarta.persistence.*;
import lombok.*;
import org.example.olympic_ot_project.core.ExamStatus;

import java.time.LocalDateTime;

@Entity
@Table(name = "exam")
@Getter
@Setter
public class Exam {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    private String name;

    @Enumerated(EnumType.STRING)
    private ExamStatus status = ExamStatus.WAITING;

    @ManyToOne
    @JoinColumn(name = "created_by", nullable = false)
    private Users createdBy;

    private Boolean shuffleOption = false;

    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "scheduled_start_at")
    private LocalDateTime scheduledStartAt;
}