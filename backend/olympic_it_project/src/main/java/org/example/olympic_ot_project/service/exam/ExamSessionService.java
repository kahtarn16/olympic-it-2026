package org.example.olympic_ot_project.service.exam;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.example.olympic_ot_project.core.AccountStudentStatus;
import org.example.olympic_ot_project.core.ExamState;
import org.example.olympic_ot_project.core.ExamStatus;
import org.example.olympic_ot_project.core.ParticipantStatus;
import org.example.olympic_ot_project.core.QuestionType;
import org.example.olympic_ot_project.dto.exam.*;
import org.example.olympic_ot_project.dto.exam.websocket.*;
import org.example.olympic_ot_project.enity.*;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.example.olympic_ot_project.repositoy.*;
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
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
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
                    this.runQuestion(examId, session.getCurrentQuestionIndex());
                } else {
                    this.runAnswer(examId, session.getCurrentQuestionIndex());
                }
            } else {
                Runnable next = session.getState() == ExamState.PREVIEW
                        ? () -> this.runQuestion(examId, session.getCurrentQuestionIndex())
                        : () -> this.runAnswer(examId, session.getCurrentQuestionIndex());
                schedule(examId, next, (int) remain);
            }
        }

        // Phục hồi lịch hẹn tự động sau khi server restart
        List<Exam> scheduledExams = examRepository
                .findByScheduledStartAtIsNotNullAndStatus(ExamStatus.WAITING);

        log.info("Phục hồi {} lịch hẹn tự động sau khi khởi động server", scheduledExams.size());

        for (Exam exam : scheduledExams) {
            LocalDateTime startAt = exam.getScheduledStartAt();
            if (startAt.isBefore(LocalDateTime.now())) {
                log.info("Lịch hẹn examId={} đã quá giờ, chạy ngay", exam.getId());
                this.autoCreateRoomAndStart(exam.getId());
            } else {
                log.info("Lên lịch lại examId={} vào lúc {}", exam.getId(), startAt);
                scheduleAutoStartTask(exam.getId(), startAt);
            }
        }
    }


    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public void startExam(Integer examId) {
        // Admin bấm nút "Bắt đầu thi" trực tiếp => KHÔNG tự động chuyển câu,
        // admin phải tự bấm "câu tiếp theo" (adminNextQuestion) sau mỗi câu.
        startExamInternal(examId, false);
    }

    /**
     * Hàm xử lý logic bắt đầu thi dùng chung cho cả 2 luồng:
     * - autoMode = false: admin bấm tay (startExam)
     * - autoMode = true: hệ thống tự động chạy theo lịch hẹn (autoStartExam)
     */
    private void startExamInternal(Integer examId, boolean autoMode) {
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
        session.setAutoMode(autoMode);
        examSessionRepository.save(session);

        this.runPreview(examId, 0);
    }

    @Transactional
    public void runPreview(Integer examId, int index) {

        ExamSession session = getRequiredSession(examId);
        List<ExamQuestion> questions = getQuestions(examId);

        if (index >= questions.size()) {
            this.finishExam(examId, session, questions.size());
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

        schedule(examId, () -> this.runQuestion(examId, index), PREVIEW_DURATION_SECONDS);
    }

    @Transactional
    public void runQuestion(Integer examId, int index) {

        ExamSession session = getRequiredSession(examId);
        List<ExamQuestion> questions = getQuestions(examId);

        if (index >= questions.size()) {
            this.finishExam(examId, session, questions.size());
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

        schedule(examId, () -> this.runAnswer(examId, index), timeLimit);
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
        payload.put("seatResults", buildSeatResults(examId, index));

        messagingTemplate.convertAndSend("/topic/exam/" + examId, payload);

        // Chỉ tự động chuyển sang câu tiếp theo (sau 3 giây) khi exam đang chạy
        // theo lịch hẹn tự động. Nếu admin điều khiển trực tiếp (autoMode = false)
        // thì dừng lại ở đây, chờ admin tự bấm "câu tiếp theo" (adminNextQuestion).
        if (Boolean.TRUE.equals(session.getAutoMode())) {
            schedule(examId, () -> this.autoNextQuestion(examId), 3);
        }
    }

    /**
     * Build danh sách trạng thái đúng/sai của từng thí sinh theo số ghế, dùng cho
     * trang trình chiếu (presentation) tô màu xanh/đỏ sơ đồ chỗ ngồi lúc SHOW_ANSWER.
     * Chỉ những thí sinh đã được gán seatNumber mới xuất hiện trong danh sách này.
     */
    private List<Map<String, Object>> buildSeatResults(Integer examId, int questionIndex) {

        List<ExamParticipant> participants = examParticipantRepository.findByExamId(examId);

        List<ExamParticipantProgress> progresses =
                progressRepository.findByExamIdAndQuestionIndex(examId, questionIndex);

        Map<Integer, Boolean> correctByUserId = progresses.stream()
                .collect(Collectors.toMap(
                        p -> p.getUser().getId(),
                        ExamParticipantProgress::getIsCorrect
                ));

        return participants.stream()
                .filter(p -> p.getSeatNumber() != null)
                .map(p -> {
                    Map<String, Object> m = new HashMap<>();
                    Integer userId = p.getUser().getId();
                    boolean answered = correctByUserId.containsKey(userId);

                    m.put("userId", userId);
                    m.put("seatNumber", p.getSeatNumber());
                    m.put("fullName", p.getUser().getFullName());
                    m.put("answered", answered);
                    m.put("isCorrect", answered ? correctByUserId.get(userId) : null);
                    return m;
                })
                .toList();
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
        submittedPayload.put("seatNumber", participant.getSeatNumber());
        submittedPayload.put("questionIndex", index);

        messagingTemplate.convertAndSend("/topic/exam/" + examId, submittedPayload);

        Map<String, Object> adminPayload = new HashMap<>();
        adminPayload.put("userId", participant.getUser().getId());
        adminPayload.put("fullName", participant.getUser().getFullName());
        adminPayload.put("seatNumber", participant.getSeatNumber());
        adminPayload.put("questionIndex", index);
        adminPayload.put("selectedOptionId", progress.getSelectedOptionId());
        adminPayload.put("answerText", progress.getAnswerText());
        adminPayload.put("isCorrect", correct);
        adminPayload.put("answeredAt", progress.getAnsweredAt());

        messagingTemplate.convertAndSend("/topic/exam/" + examId + "/admin-submissions", adminPayload);

        return SubmitAnswerResponse.builder()
                .questionIndex(index)
                .isCorrect(correct)
                .currentScore(
                        participant.getScore()
                )
                .build();
    }

    /**
     * Admin sửa lại kết quả đúng/sai cho các bài nộp CÂU TỰ LUẬN trong lúc đang
     * ở màn SHOW_ANSWER (do so sánh chuỗi tự động có thể chấm sai, vd đáp án mẫu
     * là "Thành phố Hồ Chí Minh" nhưng thí sinh chỉ ghi "Hồ Chí Minh").
     * Chỉ áp dụng được cho câu hỏi đang hiển thị đáp án (SHOW_ANSWER) của đúng
     * câu đó — khi admin bấm "câu tiếp theo", state đổi sang câu khác thì sẽ
     * không sửa được câu cũ nữa.
     */
    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public void adminRegradeAnswers(Integer examId, AdminRegradeRequest request) {

        if (request.getItems() == null || request.getItems().isEmpty()) {
            throw new AppException(ErrorCode.INVALID_STATE);
        }

        Integer questionIndex = request.getQuestionIndex();
        List<ExamQuestion> questions = getQuestions(examId);

        if (questionIndex == null || questionIndex < 0 || questionIndex >= questions.size()) {
            throw new AppException(ErrorCode.QUESTION_NOT_FOUND);
        }

        ExamSession session = getRequiredSession(examId);

        // Chỉ cho sửa khi đang đứng ở màn SHOW_ANSWER của đúng câu đang xét
        if (session.getState() != ExamState.SHOW_ANSWER
                || !Objects.equals(session.getCurrentQuestionIndex(), questionIndex)) {
            throw new AppException(ErrorCode.INVALID_STATE);
        }

        Question question = getQuestion(questions, questionIndex);

        if (question.getType() != QuestionType.ESSAY_TEXT
                && question.getType() != QuestionType.ESSAY_MEDIA) {
            throw new AppException(ErrorCode.INVALID_QUESTION_TYPE);
        }

        for (AdminRegradeRequest.Item item : request.getItems()) {

            ExamParticipantProgress progress = progressRepository
                    .findByExamIdAndUserIdAndQuestionIndex(examId, item.getUserId(), questionIndex)
                    .orElse(null);

            if (progress == null || progress.getAnsweredAt() == null) {
                log.warn("Bỏ qua regrade: examId={}, userId={}, questionIndex={} chưa nộp bài",
                        examId, item.getUserId(), questionIndex);
                continue;
            }

            boolean oldCorrect = Boolean.TRUE.equals(progress.getIsCorrect());
            boolean newCorrect = Boolean.TRUE.equals(item.getIsCorrect());

            if (oldCorrect == newCorrect) {
                continue;
            }

            progress.setIsCorrect(newCorrect);
            progressRepository.save(progress);

            ExamParticipant participant = examParticipantRepository
                    .findByExamIdAndUserId(examId, item.getUserId())
                    .orElseThrow(() -> new AppException(ErrorCode.PARTICIPANT_NOT_FOUND));

            int delta = newCorrect ? question.getScore() : -question.getScore();
            participant.setScore(participant.getScore() + delta);
            examParticipantRepository.save(participant);
        }

        Map<String, Object> payload = new HashMap<>();
        payload.put("type", "REGRADE");
        payload.put("questionIndex", questionIndex);
        payload.put("seatResults", buildSeatResults(examId, questionIndex));
        payload.put("leaderboard", buildLeaderboard(examId));

        messagingTemplate.convertAndSend("/topic/exam/" + examId, payload);
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

        antiCheatLogRepository.deleteByExamIdAndUserId(examId, userId);

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
            this.finishExam(examId, session, questions.size());
            return;
        }

        this.runPreview(examId, nextIndex);
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

    private void validateExamReadyToStart(Integer examId) {
        List<ExamQuestion> questions = getQuestions(examId);
        if (questions.isEmpty()) {
            throw new AppException(ErrorCode.EXAM_NO_QUESTIONS);
        }

        List<ExamParticipant> participants = examParticipantRepository.findByExamId(examId);
        if (participants.isEmpty()) {
            throw new AppException(ErrorCode.EXAM_NO_PARTICIPANTS);
        }
    }

    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public void createRoom(Integer examId) {
        createRoomInternal(examId);
    }

    private void createRoomInternal(Integer examId) {
        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        ExamSession session = getOrCreateSession(examId);

        if (session.getState() != ExamState.WAITING) {
            throw new AppException(ErrorCode.INVALID_STATE);
        }

        validateExamReadyToStart(examId);

        exam.setStatus(ExamStatus.ROOM_READY);
        examRepository.save(exam);

        session.setState(ExamState.ROOM_READY);
        session.setCurrentQuestionIndex(null);
        session.setCurrentQuestionStartedAt(null);
        session.setCurrentQuestionEndAt(null);
        session.setQuestionDuration(null);
        session.setLocked(false);
        session.setAutoMode(null);

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
        session.setAutoMode(null);

        examSessionRepository.save(session);

        List<ExamParticipant> participants =
                examParticipantRepository.findByExamId(examId);

        participants.forEach(p -> {
            p.setScore(0);
            p.setStatus(ParticipantStatus.INVITED);
        });
        examParticipantRepository.saveAll(participants);

        antiCheatLogRepository.deleteByExamId(examId);

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
                                .seatNumber(p.getSeatNumber())
                                .build())
                        .toList();

        Map<String, Object> payload = new HashMap<>();

        payload.put("type", "ROOM_UPDATE");
        payload.put("joinedCount", participants.size());
        payload.put("totalParticipants", total);
        payload.put("participants", participants);

        messagingTemplate.convertAndSend("/topic/exam/" + examId, payload);
    }




    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public void scheduleAutoStart(Integer examId, LocalDateTime startAt) {

        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        if (exam.getStatus() != ExamStatus.WAITING) {
            throw new AppException(ErrorCode.INVALID_STATE);
        }

        if (startAt.isBefore(LocalDateTime.now())) {
            throw new AppException(ErrorCode.INVALID_STATE);
        }

        validateExamReadyToStart(examId);

        exam.setScheduledStartAt(startAt);
        examRepository.save(exam);

        log.info("Đã đặt lịch tự động cho examId={} vào lúc {}", examId, startAt);

        scheduleAutoStartTask(examId, startAt);
    }

    private void scheduleAutoStartTask(Integer examId, LocalDateTime startAt) {
        cancelTask(examId);

        Date fireAt = Date.from(startAt.atZone(java.time.ZoneId.systemDefault()).toInstant());

        log.info("Lên lịch task cho examId={}, sẽ bắn lúc {} (server time now: {})",
                examId, fireAt, new Date());

        // Dùng this thay vì self hoặc ApplicationContext
        tasks.put(examId,
                taskScheduler.schedule(() -> this.autoCreateRoomAndStart(examId), fireAt));
    }

    @Transactional
    public void autoCreateRoomAndStart(Integer examId) {

        log.info("[AUTO] Bắt đầu tự động tạo phòng cho examId={}", examId);

        Exam exam = examRepository.findById(examId).orElse(null);

        if (exam == null) {
            log.warn("[AUTO] examId={} không tồn tại, bỏ qua", examId);
            return;
        }

        if (exam.getStatus() != ExamStatus.WAITING) {
            log.warn("[AUTO] examId={} không còn ở trạng thái WAITING (đang là {}), bỏ qua",
                    examId, exam.getStatus());
            return;
        }

        // Validate TRƯỚC khi gọi, tránh để exception ném ra làm mark rollbackOnly
        List<ExamQuestion> questions = getQuestions(examId);
        List<ExamParticipant> participants = examParticipantRepository.findByExamId(examId);

        if (questions.isEmpty() || participants.isEmpty()) {
            log.warn("[AUTO] examId={} không đủ điều kiện tạo phòng (câu hỏi={}, thí sinh={}), hủy lịch hẹn",
                    examId, questions.size(), participants.size());
            exam.setScheduledStartAt(null);
            examRepository.save(exam);
            return;
        }

        exam.setScheduledStartAt(null);
        examRepository.save(exam);

        // Gọi method internal trực tiếp, không qua proxy
        createRoomInternal(examId);
        log.info("[AUTO] Đã tạo phòng thành công cho examId={}, sẽ tự start sau 30s", examId);
        schedule(examId, () -> this.autoStartExam(examId), 30);
    }

    @Transactional
    public void autoStartExam(Integer examId) {

        log.info("[AUTO] Kiểm tra để tự động bắt đầu thi examId={}", examId);

        ExamSession session = examSessionRepository.findByExamId(examId).orElse(null);

        if (session == null) {
            log.warn("[AUTO] examId={} không có session, bỏ qua", examId);
            return;
        }

        if (session.getState() != ExamState.ROOM_READY) {
            log.warn("[AUTO] examId={} không còn ở ROOM_READY (đang là {}), bỏ qua",
                    examId, session.getState());
            return;
        }

        try {
            this.startExamInternal(examId, true);
        } catch (Exception e) {
            log.error("[AUTO] Lỗi khi tự động bắt đầu thi examId={}: {}", examId, e.getMessage(), e);
        }
    }

    @Transactional
    public void autoNextQuestion(Integer examId) {
        ExamSession session = examSessionRepository.findByExamId(examId).orElse(null);

        if (session == null) {
            return;
        }

        if (session.getState() != ExamState.SHOW_ANSWER) {
            log.warn("[AUTO] examId={} không ở SHOW_ANSWER (đang là {}), bỏ qua",
                    examId, session.getState());
            return;
        }

        try {
            this.adminNextQuestion(examId);
            log.info("[AUTO] Đã chuyển sang câu hỏi tiếp theo examId={}", examId);
        } catch (Exception e) {
            log.error("[AUTO] Lỗi khi chuyển sang câu hỏi tiếp theo examId={}: {}", examId, e.getMessage(), e);
        }
    }

    @Transactional
    @PreAuthorize("hasRole('ADMIN')")
    public void cancelAutoStart(Integer examId) {

        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        exam.setScheduledStartAt(null);
        examRepository.save(exam);

        cancelTask(examId);

        log.info("Đã hủy lịch hẹn tự động cho examId={}", examId);
    }
}