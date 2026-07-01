package org.example.olympic_ot_project.enity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "question_option")
@Getter
@Setter
public class QuestionOption {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "question_id", nullable = false)
    private Question question;

    private Character label;

    private String contentText;

    private String imageUrl;

    private Boolean isCorrect = false;
}