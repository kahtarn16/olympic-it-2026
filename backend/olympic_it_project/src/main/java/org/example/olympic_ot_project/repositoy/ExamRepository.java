package org.example.olympic_ot_project.repositoy;

import io.lettuce.core.dynamic.annotation.Param;
import org.example.olympic_ot_project.enity.Exam;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

@Repository
public interface ExamRepository extends JpaRepository<Exam, Integer> {
    @Query("""
    SELECT e FROM Exam e
    JOIN FETCH e.createdBy
    WHERE (:keyword IS NULL OR LOWER(e.name) LIKE LOWER(CONCAT('%', :keyword, '%')))
""")
    Page<Exam> search(@Param("keyword") String keyword, Pageable pageable);
}
