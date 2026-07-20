package org.example.olympic_ot_project.repositoy;

import org.example.olympic_ot_project.enity.ExamAntiCheatLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ExamAntiCheatLogRepository
        extends JpaRepository<ExamAntiCheatLog,Integer> {

    Optional<ExamAntiCheatLog> findTopByExamIdAndUserIdOrderByCreatedAtDesc(
            Integer examId,
            Integer userId
    );

    List<ExamAntiCheatLog> findByExamIdOrderByCreatedAtDesc(Integer examId);

    Integer countByExamIdAndUserId(Integer examId, Integer userId);

    void deleteByExamId(Integer examId);

    void deleteByExamIdAndUserId(Integer examId, Integer userId);
}