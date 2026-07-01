package org.example.olympic_ot_project.repositoy;

import org.example.olympic_ot_project.enity.AcademicYear;
import org.example.olympic_ot_project.enity.Classes;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ClassesRepository extends JpaRepository<Classes, Integer> {
    boolean existsByClassNameAndAcademicYearIdAndIdNot(String className,Integer academicYearId,Integer id);
    List<Classes> findByAcademicYearId(Integer academicYearId);
    boolean existsByClassNameAndAcademicYearId(String className, Integer academicYearId);
    @Query("SELECT COUNT(u) FROM Users u WHERE u.classes.id = :classId")
    long countUsersByClassId(Integer classId);
    Boolean existsByAcademicYear(AcademicYear year);
    Boolean existsByClassName(String className);
    boolean existsById(Integer id);
}
