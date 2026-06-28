package org.example.olympic_ot_project.service.academicyear;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.academicyear.AcademicYearResponse;
import org.example.olympic_ot_project.dto.academicyear.CreateAcademicYearRequest;
import org.example.olympic_ot_project.dto.academicyear.UpdateAcademicYearRequest;
import org.example.olympic_ot_project.enity.AcademicYear;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.example.olympic_ot_project.repositoy.AcademicYearRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class AcademicYearService {
    final private AcademicYearRepository academicYearRepository;

    public void createAcademicYear(CreateAcademicYearRequest request) {
        if (academicYearRepository.existsByYearName(request.getAcademicYearName())) {
            throw new AppException(ErrorCode.ACADEMIC_YEAR_USED);
        }

        AcademicYear academicYear = new AcademicYear();
        academicYear.setYearName(request.getAcademicYearName());

        academicYearRepository.save(academicYear);
    }

    public void updateAcademicYear(Integer id, UpdateAcademicYearRequest request) {

        AcademicYear academicYear = academicYearRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.ACADEMIC_YEAR_NOT_FOUND));

        boolean exists = academicYearRepository
                .existsByYearNameAndIdNot(request.getAcademicYearName(), id);

        if (exists) {
            throw new AppException(ErrorCode.ACADEMIC_YEAR_USED);
        }

        academicYear.setYearName(request.getAcademicYearName());
        academicYearRepository.save(academicYear);
    }

    public void deleteAcademicYear(Integer id) {
        AcademicYear academicYear = academicYearRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.ACADEMIC_YEAR_NOT_FOUND));

        academicYearRepository.delete(academicYear);
    }

    private AcademicYearResponse toDto(AcademicYear entity) {
        AcademicYearResponse dto = new AcademicYearResponse();
        dto.setId(entity.getId());
        dto.setYearName(entity.getYearName());
        return dto;
    }

    public List<AcademicYearResponse> getAll() {
        return academicYearRepository.findAll()
                .stream()
                .map(this::toDto)
                .toList();
    }
}
