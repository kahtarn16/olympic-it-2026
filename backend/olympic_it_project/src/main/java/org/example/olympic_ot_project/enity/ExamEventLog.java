package org.example.olympic_ot_project.enity;

import jakarta.persistence.Column;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

public class ExamEventLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    private Integer examId;
    private Integer userId;
    private String eventType;

    @Column(columnDefinition = "JSON")
    private String payload;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
