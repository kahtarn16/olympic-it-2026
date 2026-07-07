package org.example.olympic_ot_project.enity;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ExamParticipantProgressRepository
        extends JpaRepository<ExamParticipantProgress,Integer> {

    Optional<ExamParticipantProgress> findByExamIdAndUserIdAndQuestionIndex(
            Integer examId,
            Integer userId,
            Integer questionIndex
    );
}
