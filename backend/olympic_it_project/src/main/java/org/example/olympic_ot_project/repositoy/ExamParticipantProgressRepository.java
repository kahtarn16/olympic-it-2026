package org.example.olympic_ot_project.repositoy;

import org.example.olympic_ot_project.enity.ExamParticipantProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ExamParticipantProgressRepository
        extends JpaRepository<ExamParticipantProgress,Integer> {

    Optional<ExamParticipantProgress> findByExamIdAndUserIdAndQuestionIndex(
            Integer examId,
            Integer userId,
            Integer questionIndex
    );
    void deleteByExamId(Integer examId);
    int countByExamIdAndUserIdAndIsCorrectTrue(Integer examId, Integer userId);
    List<ExamParticipantProgress> findByExamIdAndQuestionIndex(Integer examId, Integer questionIndex);
}
