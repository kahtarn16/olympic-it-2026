package org.example.olympic_ot_project.service.exam;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.core.AccountStudentStatus;
import org.example.olympic_ot_project.core.ExamState;
import org.example.olympic_ot_project.core.ExamStatus;
import org.example.olympic_ot_project.core.ParticipantStatus;
import org.example.olympic_ot_project.dto.exam.*;
import org.example.olympic_ot_project.dto.exam.websocket.*;
import org.example.olympic_ot_project.enity.*;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.example.olympic_ot_project.repositoy.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.TaskScheduler;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ScheduledFuture;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class ExamSessionService {

    private static final int PREVIEW_DURATION_SECONDS = 5;
    private static final int DEFAULT_QUESTION_TIME_LIMIT = 30;

    private final Map<Integer, ScheduledFuture<?>> tasks = new ConcurrentHashMap<>();

    private final ExamSessionRepository examSessionRepository;
    private final ExamQuestionRepository examQuestionRepository;
    private final ExamRepository examRepository;
    private final ExamParticipantRepository examParticipantRepository;
    private final ExamParticipantProgressRepository progressRepository;
    private final QuestionOptionRepository optionRepository;
    private final QuestionRepository questionRepository;
    private final ExamAntiCheatLogRepository antiCheatLogRepository;

    private final SimpMessagingTemplate messagingTemplate;
    private final TaskScheduler taskScheduler;
    private final UsersRepository usersRepository;

    @Autowired
    @Lazy
    private ExamSessionService self;

    @PostConstruct
    public void resumePendingSessions() {
        List<ExamSession> activeSessions = examSessionRepository
                .findByStateIn(List.of(ExamState.PREVIEW, ExamState.SHOW_QUESTION));

        for (ExamSession session : activeSessions) {
            Integer examId = session.getExam().getId();
            long remain = Duration.between(
                    LocalDateTime.now(),
                    session.getCurrentQuestionEndAt()
            ).getSeconds();

            if (remain <= 0) {
                if (session.getState() == ExamState.PREVIEW) {
                    self.runQuestion(examId, session.getCurrentQuestionIndex());
                } else {
                    self.runAnswer(examId, session.getCurrentQuestionIndex());
                }
            } else {
                Runnable next = session.getState() == ExamState.PREVIEW
                        ? () -> self.runQuestion(examId, session.getCurrentQuestionIndex())
                        : () -> self.runAnswer(examId, session.getCurrentQuestionIndex());
                schedule(examId, next, (int) remain);
            }
        }
    }


    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public void startExam(Integer examId) {
        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        ExamSession session = getOrCreateSession(examId);

        if (session.getState() != ExamState.ROOM_READY)
            throw new AppException(ErrorCode.INVALID_STATE);

        progressRepository.deleteByExamId(examId);

        List<ExamParticipant> participants = examParticipantRepository.findByExamId(examId);
        participants.forEach(p -> p.setScore(0));
        examParticipantRepository.saveAll(participants);

        exam.setStatus(ExamStatus.RUNNING);
        examRepository.save(exam);

        session.setCurrentQuestionIndex(0);
        examSessionRepository.save(session);

        self.runPreview(examId, 0);
    }

    @Transactional
    public void runPreview(Integer examId, int index) {

        ExamSession session = getRequiredSession(examId);
        List<ExamQuestion> questions = getQuestions(examId);

        if (index >= questions.size()) {
            self.finishExam(examId, session, questions.size());
            return;
        }

        Question q = getQuestion(questions, index);

        session.setState(ExamState.PREVIEW);
        session.setCurrentQuestionIndex(index);
        examSessionRepository.save(session);

        ExamPreviewDto preview =
                ExamPreviewDto.builder()
                        .index(index)
                        .totalQuestions(questions.size())
                        .duration(PREVIEW_DURATION_SECONDS)
                        .type(q.getType())
                        .level(q.getLevel())
                        .score(q.getScore())
                        .category(q.getCategory() != null ? q.getCategory().getName() : null)
                        .build();

        Map<String, Object> payload = new HashMap<>();
        payload.put("type", "PREVIEW");
        payload.put("data", preview);

        messagingTemplate.convertAndSend("/topic/exam/" + examId, payload);

        schedule(examId, () -> self.runQuestion(examId, index), PREVIEW_DURATION_SECONDS);
    }

    @Transactional
    public void runQuestion(Integer examId, int index) {

        ExamSession session = getRequiredSession(examId);
        List<ExamQuestion> questions = getQuestions(examId);

        if (index >= questions.size()) {
            self.finishExam(examId, session, questions.size());
            return;
        }

        Question q = getQuestion(questions, index);

        int timeLimit = q.getTimeLimit() != null ? q.getTimeLimit() : DEFAULT_QUESTION_TIME_LIMIT;

        session.setState(ExamState.SHOW_QUESTION);
        session.setCurrentQuestionIndex(index);
        session.setCurrentQuestionStartedAt(LocalDateTime.now());
        session.setCurrentQuestionEndAt(LocalDateTime.now().plusSeconds(timeLimit));
        session.setQuestionDuration(timeLimit);

        examSessionRepository.save(session);

        Map<String, Object> payload = new HashMap<>();
        payload.put("type", "SHOW_QUESTION");
        payload.put("currentQuestionIndex", index);
        payload.put("totalQuestions", questions.size());
        payload.put("questionData", mapToQuestionDetail(q));
        payload.put("duration", timeLimit);

        messagingTemplate.convertAndSend("/topic/exam/" + examId, payload);

        schedule(examId, () -> self.runAnswer(examId, index), timeLimit);
    }

    @Transactional
    public void runAnswer(Integer examId, int index) {

        ExamSession session = getRequiredSession(examId);
        List<ExamQuestion> questions = getQuestions(examId);

        Question q = getQuestion(questions, index);

        Integer correct = q.getOptions().stream()
                .filter(o -> Boolean.TRUE.equals(o.getIsCorrect()))
                .map(QuestionOption::getId)
                .findFirst()
                .orElse(null);

        session.setState(ExamState.SHOW_ANSWER);
        session.setCurrentQuestionEndAt(LocalDateTime.now());

        examSessionRepository.save(session);

        Map<String, Object> payload = new HashMap<>();
        payload.put("type", "SHOW_ANSWER");
        payload.put("index", index);
        payload.put("correctOptionId", correct);
        payload.put("sampleAnswer", q.getAnswer() == null ? "" : q.getAnswer());

        messagingTemplate.convertAndSend("/topic/exam/" + examId, payload);
    }

    private String normalizeAnswer(String text) {
        if (text == null) {
            return "";
        }

        return java.text.Normalizer
                .normalize(
                        text,
                        java.text.Normalizer.Form.NFD
                )
                .replaceAll("\\p{M}", "")
                .toLowerCase()
                .replaceAll("[^a-z0-9]", "")
                .trim();
    }

    private Integer getCurrentUserId() {
        Authentication authentication =
                SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || authentication.getName() == null) {
            throw new AppException(ErrorCode.UNAUTHENTICATED);
        }

        String username = authentication.getName();

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        return user.getId();
    }

    @Transactional(readOnly = true)
    @PreAuthorize("hasRole('ADMIN')")
    public ExamRestoreResponse getAdminSessionDetail(Integer examId) {

        examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        List<ExamQuestion> questions = getQuestions(examId);

        Optional<ExamSession> optionalSession =
                examSessionRepository.findByExamId(examId);

        if (optionalSession.isEmpty()) {
            return ExamRestoreResponse.builder()
                    .state(ExamState.WAITING.name())
                    .currentQuestionIndex(null)
                    .totalQuestions(questions.size())
                    .currentQuestion(null)
                    .remainingSeconds(0L)
                    .build();
        }

        ExamSession session = optionalSession.get();

        QuestionDetailDto dto = null;

        if (session.getCurrentQuestionIndex() != null && session.getCurrentQuestionIndex() < questions.size()) {
            Question q = getQuestion(questions, session.getCurrentQuestionIndex());
            dto = mapToQuestionDetail(q);
        }

        long remain = 0;

        if (session.getCurrentQuestionEndAt() != null) {
            remain = Math.max(
                    0,
                    Duration.between(
                                    LocalDateTime.now(),
                                    session.getCurrentQuestionEndAt())
                            .getSeconds());
        }

        return ExamRestoreResponse.builder()
                .state(session.getState().name())
                .currentQuestionIndex(session.getCurrentQuestionIndex())
                .totalQuestions(questions.size())
                .currentQuestion(dto)
                .remainingSeconds(remain)
                .build();
    }

    @Transactional
    public SubmitAnswerResponse submitAnswer(
            Integer examId,
            SubmitAnswerPayload payload
    ) {
        ExamSession session = getRequiredSession(examId);
        Integer userId = getCurrentUserId();

        if (session.getState() != ExamState.SHOW_QUESTION) {
            throw new AppException(ErrorCode.INVALID_QUESTION_STATE);
        }

        int index = session.getCurrentQuestionIndex();

        if (session.getCurrentQuestionEndAt()
                .isBefore(LocalDateTime.now())) {

            throw new AppException(ErrorCode.TIME_OUT);
        }

        List<ExamQuestion> questions = getQuestions(examId);

        Question question = getQuestion(
                questions,
                index
        );

        ExamParticipant participant =
                examParticipantRepository
                        .findByExamIdAndUserId(
                                examId,
                                userId
                        )
                        .orElseThrow(() ->
                                new AppException(
                                        ErrorCode.PARTICIPANT_NOT_FOUND
                                ));

        if (participant.getStatus() == ParticipantStatus.BANNED) {
            throw new AppException(ErrorCode.PARTICIPANT_BANNED);
        }

        if (participant.getStatus() != ParticipantStatus.JOINED) {
            throw new AppException(ErrorCode.PARTICIPANT_NOT_JOINED);
        }

        ExamParticipantProgress progress =
                progressRepository
                        .findByExamIdAndUserIdAndQuestionIndex(
                                examId,
                                userId,
                                index
                        )
                        .orElse(null);

        if (progress != null
                && progress.getAnsweredAt() != null) {
            return SubmitAnswerResponse.builder()
                    .questionIndex(index)
                    .isCorrect(progress.getIsCorrect())
                    .currentScore(participant.getScore())
                    .build();
        }

        if(progress == null){
            progress = new ExamParticipantProgress();
        }

        progress.setExam(participant.getExam());
        progress.setUser(participant.getUser());
        progress.setQuestionIndex(index);

        boolean correct = false;

        switch(question.getType()){
            case MCQ_TEXT,
                 MCQ_MEDIA -> {
                if(payload.getSelectedOptionId()
                        == null){

                    throw new AppException(
                            ErrorCode.OPTION_REQUIRED
                    );
                }
                QuestionOption option =
                        optionRepository
                                .findById(
                                        payload.getSelectedOptionId()
                                )
                                .orElseThrow(() ->
                                        new AppException(
                                                ErrorCode.OPTION_NOT_FOUND
                                        ));
                if(!option.getQuestion()
                        .getId()
                        .equals(question.getId())){

                    throw new AppException(
                            ErrorCode.INVALID_OPTION
                    );
                }
                correct =
                        Boolean.TRUE.equals(
                                option.getIsCorrect()
                        );
                progress.setSelectedOptionId(
                        option.getId()
                );

            }
            case ESSAY_TEXT,
                 ESSAY_MEDIA -> {

                if (payload.getAnswerText() == null
                        || payload.getAnswerText().isBlank()) {

                    throw new AppException(
                            ErrorCode.ANSWER_EMPTY
                    );
                }

                progress.setAnswerText(
                        payload.getAnswerText()
                );

                String student =
                        normalizeAnswer(
                                payload.getAnswerText()
                        );

                String correctAnswer =
                        normalizeAnswer(
                                question.getAnswer()
                        );

                correct =
                        !correctAnswer.isEmpty()
                                &&
                                (
                                        student.equals(correctAnswer)
                                                ||
                                                student.contains(correctAnswer)
                                );
            }

        }

        progress.setIsCorrect(correct);
        progress.setAnsweredAt(
                LocalDateTime.now()
        );

        try {
            progressRepository.save(progress);
        } catch (DataIntegrityViolationException e) {
            ExamParticipantProgress existing = progressRepository
                    .findByExamIdAndUserIdAndQuestionIndex(examId, userId, index)
                    .orElseThrow(() -> new AppException(ErrorCode.INVALID_QUESTION_STATE));

            return SubmitAnswerResponse.builder()
                    .questionIndex(index)
                    .isCorrect(existing.getIsCorrect())
                    .currentScore(participant.getScore())
                    .build();
        }

        if(correct){

            participant.setScore(
                    participant.getScore()
                            +
                            question.getScore()
            );

            examParticipantRepository.save(
                    participant
            );
        }

        Map<String, Object> submittedPayload = new HashMap<>();
        submittedPayload.put("type", "ANSWER_SUBMITTED");
        submittedPayload.put("userId", participant.getUser().getId());
        submittedPayload.put("fullName", participant.getUser().getFullName());
        submittedPayload.put("questionIndex", index);

        messagingTemplate.convertAndSend("/topic/exam/" + examId, submittedPayload);

        return SubmitAnswerResponse.builder()
                .questionIndex(index)
                .isCorrect(correct)
                .currentScore(
                        participant.getScore()
                )
                .build();
    }

    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public void unbanParticipant(Integer examId, Integer userId) {

        ExamParticipant participant = examParticipantRepository
                .findByExamIdAndUserId(examId, userId)
                .orElseThrow(() -> new AppException(ErrorCode.PARTICIPANT_NOT_FOUND));

        if (participant.getStatus() != ParticipantStatus.BANNED) {
            throw new AppException(ErrorCode.INVALID_STATE);
        }
        participant.setStatus(ParticipantStatus.INVITED);
        examParticipantRepository.save(participant);

        broadcastRoomUpdate(examId);
    }



    // ================= FINISH =================
    @Transactional
    public void finishExam(Integer examId, ExamSession session, int total) {

        cancelTask(examId);

        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        exam.setStatus(ExamStatus.FINISHED);
        examRepository.save(exam);

        session.setState(ExamState.FINISHED);
        examSessionRepository.save(session);

        Map<String, Object> payload = new HashMap<>();
        payload.put("type", "FINISH");
        payload.put("totalQuestions", total);
        payload.put("leaderboard", buildLeaderboard(examId));

        messagingTemplate.convertAndSend("/topic/exam/" + examId, payload);
    }

    private void schedule(Integer examId, Runnable r, int sec) {

        ExamSession session = getRequiredSession(examId);
        if (session.getState() == ExamState.FINISHED) return;

        cancelTask(examId);

        tasks.put(examId,
                taskScheduler.schedule(r,
                        Date.from(Instant.now().plusSeconds(sec))));
    }

    private void cancelTask(Integer examId) {
        ScheduledFuture<?> task = tasks.remove(examId);
        if (task != null) task.cancel(true);
    }

    // ================= HELPERS =================
    private ExamSession getRequiredSession(Integer examId) {
        return examSessionRepository.findByExamId(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));
    }

    private ExamSession getOrCreateSession(Integer examId) {
        return examSessionRepository.findByExamId(examId).orElseGet(() -> {
            Exam exam = examRepository.findById(examId)
                    .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

            ExamSession s = new ExamSession();
            s.setExam(exam);
            s.setState(ExamState.WAITING);
            s.setCurrentQuestionIndex(null);
            s.setLocked(false);

            return examSessionRepository.save(s);
        });
    }

    private List<ExamQuestion> getQuestions(Integer examId) {
        return examQuestionRepository.findByExamIdOrderByOrderIndexAsc(examId);
    }

    private Question getQuestion(List<ExamQuestion> questions, Integer index) {
        return questionRepository.findByIdWithOptionsAndCategory(
                questions.get(index).getQuestion().getId()
        ).orElseThrow(() -> new AppException(ErrorCode.QUESTION_NOT_FOUND));
    }

    private QuestionDetailDto mapToQuestionDetail(Question q) {

        return QuestionDetailDto.builder()
                .id(q.getId())
                .content(q.getContent())
                .imageUrl(q.getImageUrl())
                .videoUrl(q.getVideoUrl())
                .type(q.getType())
                .level(q.getLevel())
                .score(q.getScore())
                .category(q.getCategory() != null ? q.getCategory().getName() : null)
                .options(q.getOptions()==null ? List.of() : q.getOptions().stream().map(o ->
                        OptionDto.builder()
                                .id(o.getId())
                                .label(o.getLabel())
                                .contentText(o.getContentText())
                                .imageUrl(o.getImageUrl())
                                .build()).toList()).build();
    }

    private List<Leaderboard> buildLeaderboard(Integer examId) {

        List<ExamParticipant> participants =
                examParticipantRepository.findByExamId(examId);

        participants.sort(
                Comparator.comparingInt(ExamParticipant::getScore)
                        .reversed()
        );

        List<Leaderboard> result = new ArrayList<>();

        int rank = 0;
        int previousScore = Integer.MIN_VALUE;

        for (int i = 0; i < participants.size(); i++) {

            ExamParticipant p = participants.get(i);

            if (p.getScore() != previousScore) {
                rank = i + 1;
                previousScore = p.getScore();
            }

            result.add(
                    Leaderboard.builder()
                            .rank(rank)
                            .userId(p.getUser().getId())
                            .name(p.getUser().getFullName())
                            .score(p.getScore())
                            .build()
            );
        }

        return result;
    }

    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public void adminNextQuestion(Integer examId) {

        ExamSession session = getRequiredSession(examId);

        if (session.getState() != ExamState.SHOW_ANSWER)
            throw new AppException(ErrorCode.INVALID_STATE);

        int currentIndex = session.getCurrentQuestionIndex();
        List<ExamQuestion> questions = getQuestions(examId);

        int nextIndex = currentIndex + 1;

        if (nextIndex >= questions.size()) {
            self.finishExam(examId, session, questions.size());
            return;
        }

        self.runPreview(examId, nextIndex);
    }

    @Transactional(readOnly = true)
    public ExamSessionResponse getSessionInfo(Integer examId) {

        ExamSession session = getRequiredSession(examId);

        int totalQuestions =
                examQuestionRepository
                        .findByExamIdOrderByOrderIndexAsc(examId)
                        .size();


        int totalParticipants =
                examParticipantRepository
                        .findByExamId(examId)
                        .size();


        return ExamSessionResponse.builder()
                .examName(session.getExam().getName())

                .state(session.getState())

                .currentQuestionIndex(
                        session.getCurrentQuestionIndex()
                )

                .totalQuestions(totalQuestions)

                .totalParticipants(totalParticipants)

                .questionDuration(
                        session.getQuestionDuration()
                )

                .currentQuestionStartedAt(
                        session.getCurrentQuestionStartedAt()
                )

                .currentQuestionEndAt(
                        session.getCurrentQuestionEndAt()
                )

                .locked(
                        session.isLocked()
                )

                .build();
    }

    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public void createRoom(Integer examId) {
        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        ExamSession session = getOrCreateSession(examId);

        if (session.getState() != ExamState.WAITING) {
            throw new AppException(ErrorCode.INVALID_STATE);
        }

        exam.setStatus(ExamStatus.ROOM_READY);
        examRepository.save(exam);

        session.setState(ExamState.ROOM_READY);
        session.setCurrentQuestionIndex(null);
        session.setCurrentQuestionStartedAt(null);
        session.setCurrentQuestionEndAt(null);
        session.setQuestionDuration(null);
        session.setLocked(false);


        examSessionRepository.save(session);

        Map<String, Object> payload = new HashMap<>();
        payload.put("type", "ROOM_READY");

        messagingTemplate.convertAndSend("/topic/exam/" + examId, payload);
    }

    @Transactional(readOnly = true)
    public List<Leaderboard> getLeaderboard(Integer examId) {
        return buildLeaderboard(examId);
    }

    @Transactional(readOnly = true)
    public ExamRestoreResponse restoreExam(Integer examId) {

        examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        Integer userId = getCurrentUserId();

        ExamParticipant participant = examParticipantRepository
                .findByExamIdAndUserId(examId, userId)
                .orElse(null);

        if (participant == null || participant.getStatus() == ParticipantStatus.BANNED) {
            throw new AppException(ErrorCode.PARTICIPANT_NOT_FOUND);
        }

        Users user = usersRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        if (user.getStatus() == AccountStudentStatus.LOCKED) {
            throw new AppException(ErrorCode.PARTICIPANT_BANNED);
        }

        List<ExamQuestion> questions = getQuestions(examId);

        Optional<ExamSession> optionalSession =
                examSessionRepository.findByExamId(examId);

        if (optionalSession.isEmpty()) {
            return ExamRestoreResponse.builder()
                    .state(ExamState.WAITING.name())
                    .currentQuestionIndex(null)
                    .totalQuestions(questions.size())
                    .currentQuestion(null)
                    .remainingSeconds(0L)
                    .build();
        }

        ExamSession session = optionalSession.get();

        QuestionDetailDto dto = null;

        if (session.getCurrentQuestionIndex() != null && session.getCurrentQuestionIndex() < questions.size()) {
            Question q = getQuestion(questions, session.getCurrentQuestionIndex());
            dto = mapToQuestionDetail(q);
        }

        long remain = 0;

        if (session.getCurrentQuestionEndAt() != null) {
            remain = Math.max(
                    0,
                    Duration.between(
                                    LocalDateTime.now(),
                                    session.getCurrentQuestionEndAt())
                            .getSeconds());
        }

        return ExamRestoreResponse.builder()
                .state(session.getState().name())
                .currentQuestionIndex(session.getCurrentQuestionIndex())
                .totalQuestions(questions.size())
                .currentQuestion(dto)
                .remainingSeconds(remain)
                .build();
    }

    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public void resetExam(Integer examId) {
        cancelTask(examId);

        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        ExamSession session = getRequiredSession(examId);

        exam.setStatus(ExamStatus.WAITING);
        examRepository.save(exam);

        session.setState(ExamState.WAITING);
        session.setCurrentQuestionIndex(null);
        session.setCurrentQuestionStartedAt(null);
        session.setCurrentQuestionEndAt(null);
        session.setQuestionDuration(null);
        session.setLocked(false);

        examSessionRepository.save(session);

        List<ExamParticipant> participants =
                examParticipantRepository.findByExamId(examId);

        participants.forEach(p -> {
            p.setScore(0);
            p.setStatus(ParticipantStatus.INVITED);
        });
        examParticipantRepository.saveAll(participants);

        antiCheatLogRepository.deleteByExamId(examId);
        List<Users> bannedUsers = participants.stream()
                .map(ExamParticipant::getUser)
                .filter(u -> u.getStatus() == AccountStudentStatus.LOCKED)
                .toList();
        bannedUsers.forEach(u -> u.setStatus(AccountStudentStatus.ACTIVE));
        usersRepository.saveAll(bannedUsers);
        examParticipantRepository.saveAll(participants);

        progressRepository.deleteByExamId(examId);

        Map<String, Object> payload = new HashMap<>();
        payload.put("type", "RESET");

        messagingTemplate.convertAndSend("/topic/exam/" + examId, payload);
    }

    @Transactional(readOnly = true)
    public void broadcastRoomUpdate(Integer examId) {

        List<ExamParticipant> joined = examParticipantRepository.findByExamIdAndStatus(examId, ParticipantStatus.JOINED);

        int total = examParticipantRepository.findByExamId(examId).size();

        List<RoomParticipantDto> participants =
                joined.stream()
                        .map(p -> RoomParticipantDto.builder()
                                .userId(p.getUser().getId())
                                .fullName(p.getUser().getFullName())
                                .className(p.getUser().getClasses().getClassName() == null ? "" : p.getUser().getClasses().getClassName())
                                .build())
                        .toList();

        Map<String, Object> payload = new HashMap<>();

        payload.put("type", "ROOM_UPDATE");
        payload.put("joinedCount", participants.size());
        payload.put("totalParticipants", total);
        payload.put("participants", participants);

        messagingTemplate.convertAndSend("/topic/exam/" + examId, payload);
    }
}