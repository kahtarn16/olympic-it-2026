package org.example.olympic_ot_project.service.exam;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.config.WsPublisher;
import org.example.olympic_ot_project.core.AccountStudentStatus;
import org.example.olympic_ot_project.core.ExamStatus;
import org.example.olympic_ot_project.core.ParticipantStatus;
import org.example.olympic_ot_project.dto.exam.anticheat.AntiCheatRequest;
import org.example.olympic_ot_project.dto.exam.anticheat.AntiCheatResponse;
import org.example.olympic_ot_project.enity.Exam;
import org.example.olympic_ot_project.enity.ExamAntiCheatLog;
import org.example.olympic_ot_project.enity.ExamParticipant;
import org.example.olympic_ot_project.enity.Users;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.example.olympic_ot_project.repositoy.ExamAntiCheatLogRepository;
import org.example.olympic_ot_project.repositoy.ExamParticipantRepository;
import org.example.olympic_ot_project.repositoy.ExamRepository;
import org.example.olympic_ot_project.repositoy.UsersRepository;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AntiCheatService {

    private static final int MAX_VIOLATIONS = 3;

    private final ExamRepository examRepository;
    private final UsersRepository usersRepository;
    private final ExamParticipantRepository participantRepository;
    private final ExamAntiCheatLogRepository logRepository;
    private final WsPublisher wsPublisher;

    @Transactional
    public void recordViolation(AntiCheatRequest request) {

        if (request.getType() == null) {
            throw new AppException(ErrorCode.INVALID_ANTI_CHEAT_TYPE);
        }

        Integer userId = getCurrentUserId();

        Exam exam = examRepository.findById(request.getExamId())
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        if (exam.getStatus() != ExamStatus.RUNNING) {
            throw new AppException(ErrorCode.EXAM_NOT_RUNNING);
        }

        ExamParticipant participant = participantRepository
                .findByExamIdAndUserId(exam.getId(), userId)
                .orElseThrow(() -> new AppException(ErrorCode.PARTICIPANT_NOT_FOUND));

        if (participant.getStatus() == ParticipantStatus.BANNED) {
            throw new AppException(ErrorCode.PARTICIPANT_BANNED);
        }

        Users user = usersRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        logRepository
                .findTopByExamIdAndUserIdOrderByCreatedAtDesc(exam.getId(), userId)
                .ifPresent(last -> {
                    boolean duplicated =
                            last.getType() == request.getType()
                                    && last.getCreatedAt()
                                    .isAfter(LocalDateTime.now().minusSeconds(5));

                    if (duplicated) {
                        throw new AppException(ErrorCode.DUPLICATE_ANTI_CHEAT_EVENT);
                    }
                });

        ExamAntiCheatLog log = ExamAntiCheatLog.builder()
                .exam(exam)
                .user(user)
                .type(request.getType())
                .createdAt(LocalDateTime.now())
                .build();

        log = logRepository.save(log);

        long violationCount = logRepository.countByExamIdAndUserId(exam.getId(), userId);
        boolean banned = violationCount >= MAX_VIOLATIONS;

        if (banned) {
            participant.setStatus(ParticipantStatus.BANNED);
            participantRepository.save(participant);

            user.setStatus(AccountStudentStatus.LOCKED);
            usersRepository.save(user);
        }

        AntiCheatResponse response = AntiCheatResponse.builder()
                .userId(user.getId())
                .fullName(user.getFullName())
                .type(log.getType())
                .createdAt(log.getCreatedAt())
                .violationCount((int) violationCount)
                .banned(banned)
                .build();

        wsPublisher.banNotice(exam.getId(), response);
    }

    private Integer getCurrentUserId() {

        Authentication authentication =
                SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || authentication.getName() == null) {
            throw new AppException(ErrorCode.UNAUTHENTICATED);
        }

        Users user = usersRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        return user.getId();
    }

    @PreAuthorize("hasRole('ADMIN')")
    @Transactional(readOnly = true)
    public List<AntiCheatResponse> getViolations(Integer examId) {

        examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        return logRepository.findByExamIdOrderByCreatedAtDesc(examId)
                .stream()
                .map(log -> AntiCheatResponse.builder()
                        .userId(log.getUser().getId())
                        .fullName(log.getUser().getFullName())
                        .type(log.getType())
                        .createdAt(log.getCreatedAt())
                        .build())
                .toList();
    }
}