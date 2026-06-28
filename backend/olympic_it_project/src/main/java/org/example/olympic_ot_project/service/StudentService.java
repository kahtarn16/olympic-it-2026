package org.example.olympic_ot_project.service;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.Core.Status;
import org.example.olympic_ot_project.dto.student.CreateStudentRequest;
import org.example.olympic_ot_project.dto.student.StudentResponse;
import org.example.olympic_ot_project.dto.student.UpdateStudentRequest;
import org.example.olympic_ot_project.enity.Classes;
import org.example.olympic_ot_project.enity.Role;
import org.example.olympic_ot_project.enity.Users;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.example.olympic_ot_project.repositoy.ClassesRepository;
import org.example.olympic_ot_project.repositoy.RoleRepository;
import org.example.olympic_ot_project.repositoy.UsersRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class StudentService {
    final private UsersRepository usersRepository;
    final private ClassesRepository classesRepository;
    final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;

    public void createStudent(CreateStudentRequest request) {
        if(usersRepository.existsByUsername(request.getUsername())) {
            throw new AppException(ErrorCode.USERNAME_USED);
        }

        if (usersRepository.existsByEmail(request.getEmail())) {
            throw new AppException(ErrorCode.EMAIL_USED);
        }

        Classes c = classesRepository.findById(request.getClassId())
                .orElseThrow(() -> new AppException(ErrorCode.CLASSES_NOT_FOUND));

        Role role = roleRepository.findById(2)
                .orElseThrow(() -> new AppException(ErrorCode.ROLE_NOT_FOUND));

        Users user = new Users();
        user.setUsername(request.getUsername());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setEmail(request.getEmail());
        user.setFullName(request.getFullName());
        user.setClasses(c);
        user.setRole(role);
        user.setStatus(Status.ACTIVE);

        usersRepository.save(user);
    }

    public List<StudentResponse> getAllStudents() {
        return usersRepository.findByRole_Id(2)
                .stream()
                .map(this::toDto)
                .toList();
    }

    private StudentResponse toDto(Users u) {
        StudentResponse dto = new StudentResponse();
        dto.setId(u.getId());
        dto.setUsername(u.getUsername());
        dto.setEmail(u.getEmail());
        dto.setFullName(u.getFullName());
        dto.setClassName(u.getClasses().getClassName());
        return dto;
    }

    public void updateStudent(Integer id, UpdateStudentRequest request) {

        Users user = usersRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        Classes c = classesRepository.findById(request.getClassId())
                .orElseThrow(() -> new AppException(ErrorCode.CLASSES_NOT_FOUND));

        user.setFullName(request.getFullName());
        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setClasses(c);

        usersRepository.save(user);
    }

    public void deleteStudent(Integer id) {

        Users user = usersRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        user.setStatus(Status.LOCKED);

        usersRepository.save(user);
    }

    public void unlockStudent(Integer id) {

        Users user = usersRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        user.setStatus(Status.ACTIVE);

        usersRepository.save(user);
    }
}
