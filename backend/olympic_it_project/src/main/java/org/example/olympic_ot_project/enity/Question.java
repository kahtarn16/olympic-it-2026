package org.example.olympic_ot_project.enity;

import jakarta.persistence.*;
import lombok.*;
import org.example.olympic_ot_project.core.QuestionLevel;
import org.example.olympic_ot_project.core.QuestionType;

import java.util.List;

@Entity
@Table(name = "question")
@Getter
@Setter
public class Question {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    @Enumerated(EnumType.STRING)
    private QuestionType type;

    @Enumerated(EnumType.STRING)
    private QuestionLevel level;

    @Column(columnDefinition = "TEXT")
    private String answer;

    @Column(nullable = false)
    private Integer score;

    @Column(name = "time_limit")
    private Integer timeLimit;

    private String imageUrl;

    private String videoUrl;

    @OneToMany(mappedBy = "question", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<QuestionOption> options;

    @ManyToOne
    @JoinColumn(name = "category_id")
    private Category category;
}