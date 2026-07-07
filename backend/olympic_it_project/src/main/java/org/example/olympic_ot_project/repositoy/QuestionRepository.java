package org.example.olympic_ot_project.repositoy;

import io.lettuce.core.dynamic.annotation.Param;
import org.example.olympic_ot_project.enity.Question;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface QuestionRepository extends JpaRepository<Question, Integer> {
    Page<Question> findAll(Pageable pageable);
    Page<Question> findByCategoryId(Integer categoryId, Pageable pageable);
    @Query("""
        SELECT q FROM Question q 
        LEFT JOIN FETCH q.options 
        LEFT JOIN FETCH q.category 
        WHERE q.id = :id
    """)
    Optional<Question> findByIdWithOptionsAndCategory(@Param("id") Integer id);
}
