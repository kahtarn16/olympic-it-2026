package org.example.olympic_ot_project.repositoy;

import org.example.olympic_ot_project.enity.ExamQuestion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ExamQuestionRepository extends JpaRepository<ExamQuestion, Integer> {
 Optional<ExamQuestion> findByExamIdAndQuestionId(Integer examId, Integer questionId);
 List<ExamQuestion> findByExamIdOrderByOrderIndexAsc(Integer examId);
 Integer countByExamId(Integer examId);
}
