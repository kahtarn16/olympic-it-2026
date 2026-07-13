package org.example.olympic_ot_project.service.student;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.core.ExamState;
import org.example.olympic_ot_project.core.ExamStatus;
import org.example.olympic_ot_project.core.ParticipantStatus;
import org.example.olympic_ot_project.dto.exam.Leaderboard;
import org.example.olympic_ot_project.dto.exam.websocket.OptionDto;
import org.example.olympic_ot_project.dto.exam.websocket.QuestionDetailDto;
import org.example.olympic_ot_project.dto.student.ExamSessionDto;
import org.example.olympic_ot_project.dto.student.JoinRoomResponse;
import org.example.olympic_ot_project.dto.student.StudentExamDetailResponse;
import org.example.olympic_ot_project.dto.student.StudentExamResultResponse;
import org.example.olympic_ot_project.enity.*;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.example.olympic_ot_project.repositoy.*;
import org.example.olympic_ot_project.service.exam.ExamSessionService;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class StudentExamService {

    private final UsersRepository usersRepository;
    private final ExamRepository examRepository;
    private final ExamSessionRepository examSessionRepository;
    private final ExamParticipantRepository examParticipantRepository;
    private final ExamQuestionRepository examQuestionRepository;
    private final ExamSessionService examSessionService;

    public JoinRoomResponse joinRoom(Integer examId, String username) {

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        ExamSession session = examSessionRepository.findByExamId(examId)
                .orElseThrow(() -> new AppException(ErrorCode.SESSION_NOT_FOUND));

        ExamParticipant participant = examParticipantRepository
                .findByExamIdAndUserId(examId, user.getId())
                .orElseThrow(() -> new AppException(ErrorCode.PARTICIPANT_NOT_FOUND));

        if (participant.getStatus() == ParticipantStatus.BANNED) {
            throw new AppException(ErrorCode.PARTICIPANT_BANNED);
        }

        if (session.getState() == ExamState.WAITING) {
            throw new AppException(ErrorCode.ROOM_NOT_READY);
        }

        participant.setStatus(ParticipantStatus.JOINED);
        examParticipantRepository.save(participant);

        examSessionService.broadcastRoomUpdate(examId);

        return JoinRoomResponse.builder()
                .examId(examId)
                .examName(exam.getName())
                .state(session.getState().name())
                .message(
                        session.getState() == ExamState.ROOM_READY
                                ? "WAITING_ADMIN_START"
                                : "JOIN_SUCCESS"
                )
                .build();
    }

    public ExamSessionDto getSession(Integer examId) {

        ExamSession session = examSessionRepository.findByExamId(examId)
                .orElseThrow(() -> new AppException(ErrorCode.SESSION_NOT_FOUND));

        int total = examQuestionRepository.countByExamId(examId);

        List<ExamQuestion> questions =
                examQuestionRepository.findByExamIdOrderByOrderIndexAsc(examId);

        QuestionDetailDto currentQuestion = null;

        if (session.getCurrentQuestionIndex() != null &&
                session.getCurrentQuestionIndex() < questions.size() &&
                (session.getState() == ExamState.SHOW_QUESTION
                        || session.getState() == ExamState.SHOW_ANSWER)) {

            Question q = questions
                    .get(session.getCurrentQuestionIndex())
                    .getQuestion();

            currentQuestion = mapToQuestionDetail(q);
        }

        Long remainingSeconds = 0L;

        if (session.getCurrentQuestionEndAt() != null) {

            remainingSeconds = java.time.Duration.between(
                    java.time.LocalDateTime.now(),
                    session.getCurrentQuestionEndAt()
            ).getSeconds();

            if (remainingSeconds < 0) remainingSeconds = 0L;
        }

        return ExamSessionDto.builder()
                .state(session.getState().name())
                .currentQuestionIndex(session.getCurrentQuestionIndex())
                .totalQuestions(total)
                .questionDuration(session.getQuestionDuration())
                .currentQuestionStartedAt(session.getCurrentQuestionStartedAt())
                .currentQuestionEndAt(session.getCurrentQuestionEndAt())
                .currentQuestion(currentQuestion)
                .remainingSeconds(remainingSeconds)
                .build();
    }

    private QuestionDetailDto mapToQuestionDetail(Question q) {
        return QuestionDetailDto.builder()
                .id(q.getId())
                .content(q.getContent())
                .type(q.getType())
                .level(q.getLevel())
                .imageUrl(q.getImageUrl())
                .videoUrl(q.getVideoUrl())
                .timeLimit(q.getTimeLimit())
                .options(
                        q.getOptions() == null ? List.of()
                                : q.getOptions().stream()
                                .map(opt -> OptionDto.builder()
                                        .id(opt.getId())
                                        .label(opt.getLabel())
                                        .contentText(opt.getContentText())
                                        .imageUrl(opt.getImageUrl())
                                        .build())
                                .toList()
                )
                .build();
    }

    public StudentExamDetailResponse getExamDetail(Integer examId) {

        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        int totalQuestions = examQuestionRepository.countByExamId(examId);

        return StudentExamDetailResponse.builder()
                .id(exam.getId())
                .name(exam.getName())
                .status(exam.getStatus())
                .totalQuestions(totalQuestions)
                .build();
    }

    public StudentExamResultResponse getExamResult(Integer examId) {

        Integer userId = getCurrentUserId();

        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        if (exam.getStatus() != ExamStatus.FINISHED) {
            throw new AppException(ErrorCode.EXAM_NOT_FINISHED);
        }

        ExamParticipant participant =
                examParticipantRepository
                        .findByExamIdAndUserId(examId, userId)
                        .orElseThrow(() ->
                                new AppException(ErrorCode.PARTICIPANT_NOT_FOUND));

        List<Leaderboard> leaderboard =
                examSessionService.getLeaderboard(examId);

        Leaderboard me = leaderboard.stream()
                .filter(lb -> lb.getUserId().equals(userId))
                .findFirst()
                .orElseThrow(() ->
                        new AppException(ErrorCode.PARTICIPANT_NOT_FOUND));

        return StudentExamResultResponse.builder()
                .score(participant.getScore())
                .rank(me.getRank())
                .totalParticipants(leaderboard.size())
                .leaderboard(leaderboard)
                .build();
    }

    private Integer getCurrentUserId() {

        Authentication authentication =
                SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || authentication.getName() == null) {
            throw new AppException(ErrorCode.UNAUTHENTICATED);
        }

        String username = authentication.getName();

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() ->
                        new AppException(ErrorCode.USER_NOT_FOUND));

        return user.getId();
    }
}
