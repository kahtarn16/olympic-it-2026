package org.example.olympic_ot_project.repositoy;

import org.example.olympic_ot_project.enity.Question;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface QuestionRepository extends JpaRepository<Question, Integer> {
    Page<Question> findAll(Pageable pageable);
    Page<Question> findByCategoryId(Integer categoryId, Pageable pageable);
}
