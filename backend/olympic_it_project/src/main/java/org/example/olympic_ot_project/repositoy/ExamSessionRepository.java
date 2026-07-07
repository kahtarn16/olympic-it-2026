package org.example.olympic_ot_project.repositoy;

import org.example.olympic_ot_project.core.ExamState;
import org.example.olympic_ot_project.enity.ExamSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ExamSessionRepository extends JpaRepository<ExamSession, Integer> {
    Optional<ExamSession> findByExamId(Integer examId);
    List<ExamSession> findByStateIn(List<ExamState> states);

}
