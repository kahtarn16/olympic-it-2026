package org.example.olympic_ot_project.repositoy;

import org.example.olympic_ot_project.enity.AcademicYear;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AcademicYearRepository extends JpaRepository<AcademicYear, Integer> {
    Boolean existsByYearName(String yearName);
    Boolean existsByYearNameAndIdNot(String yearName, Integer Id);
    Optional<AcademicYear> findByYearName(String yearName);
}
