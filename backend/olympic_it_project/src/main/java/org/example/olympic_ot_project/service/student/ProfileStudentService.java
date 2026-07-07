package org.example.olympic_ot_project.service.student;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.student.MyExamResponse;
import org.example.olympic_ot_project.dto.student.StudentMeResponse;
import org.example.olympic_ot_project.enity.ExamParticipant;
import org.example.olympic_ot_project.enity.Users;
import org.example.olympic_ot_project.repositoy.ExamParticipantRepository;
import org.example.olympic_ot_project.repositoy.UsersRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ProfileStudentService {
    final private UsersRepository usersRepository;
    private final ExamParticipantRepository examParticipantRepository;

    public StudentMeResponse getMe(String username) {

        Users u = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        StudentMeResponse dto = new StudentMeResponse();
        dto.setId(u.getId());
        dto.setUsername(u.getUsername());
        dto.setFullName(u.getFullName());
        dto.setEmail(u.getEmail());

        dto.setClassName(u.getClasses() != null
                ? u.getClasses().getClassName()
                : null);

        dto.setAcademicYear(u.getClasses() != null
                ? u.getClasses().getAcademicYear().getYearName()
                : null);

        return dto;
    }

    public List<MyExamResponse> getMyExams(String username) {

        Users u = usersRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<ExamParticipant> list =
                examParticipantRepository.findMyExams(u.getId());

        return list.stream().map(ep -> {
            MyExamResponse dto = new MyExamResponse();
            dto.setExamId(ep.getExam().getId());
            dto.setExamName(ep.getExam().getName());
            dto.setStatus(ep.getExam().getStatus().name());
            return dto;
        }).toList();
    }
}
