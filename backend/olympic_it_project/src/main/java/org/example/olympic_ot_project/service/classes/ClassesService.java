package org.example.olympic_ot_project.service.classes;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.classes.ClassResponse;
import org.example.olympic_ot_project.dto.classes.CreateClassRequest;
import org.example.olympic_ot_project.dto.classes.UpdateClassRequest;
import org.example.olympic_ot_project.enity.AcademicYear;
import org.example.olympic_ot_project.enity.Classes;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.example.olympic_ot_project.repositoy.AcademicYearRepository;
import org.example.olympic_ot_project.repositoy.ClassesRepository;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@PreAuthorize("hasRole('ADMIN')")
@Transactional
@RequiredArgsConstructor
public class ClassesService {
    private final ClassesRepository classRepository;
    private final AcademicYearRepository academicYearRepository;

    public void createClasses(CreateClassRequest request) {
        AcademicYear year = academicYearRepository.findById(request.getAcademicYearId())
                .orElseThrow(() -> new AppException(ErrorCode.ACADEMIC_YEAR_NOT_FOUND));

        if (classRepository.existsByClassNameAndAcademicYearId(request.getClassName(), request.getAcademicYearId())) {
            throw new AppException(ErrorCode.CLASSES_USED);
        }

        Classes c = new Classes();
        c.setClassName(request.getClassName());
        c.setAcademicYear(year);
        classRepository.save(c);
    }

    public void updateClasses(Integer id, UpdateClassRequest request) {

        Classes c = classRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSES_NOT_FOUND));

        boolean exists = classRepository.existsByClassNameAndAcademicYearIdAndIdNot(
                request.getClassName(),
                c.getAcademicYear().getId(),
                id
        );

        AcademicYear year = academicYearRepository.findById(request.getAcademicYearId())
                .orElseThrow(() -> new AppException(ErrorCode.ACADEMIC_YEAR_NOT_FOUND));

        if (exists) {
            throw new AppException(ErrorCode.CLASSES_USED);
        }

        if (classRepository.existsByClassName(request.getClassName())) {
            throw new AppException(ErrorCode.CLASS_NAME_EXISTS);
        }

        c.setClassName(request.getClassName());
        c.setAcademicYear(year);

        classRepository.save(c);
    }

    public void delete(Integer id) {

        Classes c = classRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.CLASSES_NOT_FOUND));

        long count = classRepository.countUsersByClassId(id);

        if (count > 0) {
            throw new AppException(ErrorCode.CLASSES_HAS_STUDENTS);
        }

        classRepository.delete(c);
    }

    public List<ClassResponse> getByAcademicYear(Integer academicYearId) {

        List<Classes> list;

        if (academicYearId == null) {
            list = classRepository.findAll();
        } else {
            list = classRepository.findByAcademicYearId(academicYearId);
        }

        return list.stream()
                .map(this::toDto)
                .toList();
    }

    private ClassResponse toDto(Classes c) {
        ClassResponse dto = new ClassResponse();
        dto.setId(c.getId());
        dto.setClassName(c.getClassName());
        dto.setAcademicYearId(c.getAcademicYear().getId());
        return dto;
    }
}
