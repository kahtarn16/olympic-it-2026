package org.example.olympic_ot_project.enity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "exam_question",
        uniqueConstraints = @UniqueConstraint(columnNames = {"exam_id", "question_id"}))
@Getter
@Setter
public class ExamQuestion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "exam_id", nullable = false)
    private Exam exam;

    @ManyToOne
    @JoinColumn(name = "question_id", nullable = false)
    private Question question;

    private Integer orderIndex;
}