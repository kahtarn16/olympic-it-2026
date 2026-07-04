package org.example.olympic_ot_project.repositoy;

import org.example.olympic_ot_project.enity.QuestionOption;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import javax.swing.text.html.Option;
import java.util.List;
import java.util.Optional;

@Repository
public interface QuestionOptionRepository extends JpaRepository<QuestionOption, Integer> {
    void deleteByQuestionId(Integer questionId);
    List<QuestionOption> findByQuestionId(Integer id);
}
