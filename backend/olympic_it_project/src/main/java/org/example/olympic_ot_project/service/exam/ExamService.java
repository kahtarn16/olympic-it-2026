package org.example.olympic_ot_project.service.exam;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.core.AccountStudentStatus;
import org.example.olympic_ot_project.core.ExamStatus;
import org.example.olympic_ot_project.core.ParticipantStatus;
import org.example.olympic_ot_project.dto.exam.*;
import org.example.olympic_ot_project.dto.exam.question.QuestionDetailResponse;
import org.example.olympic_ot_project.dto.exam.question.QuestionResponse;
import org.example.olympic_ot_project.dto.exam.question.RemoveQuestionRequest;
import org.example.olympic_ot_project.enity.*;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.example.olympic_ot_project.repositoy.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class ExamService {
    private final ExamRepository examRepository;
    private final QuestionRepository questionRepository;
    private final ExamQuestionRepository examQuestionRepository;
    private final UsersRepository usersRepository;
    private final ExamParticipantRepository examParticipantRepository;

    public void createExam(CreateExamRequest request) {

        Users creator = usersRepository.findById(request.getCreatedById())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        Exam exam = new Exam();
        exam.setName(request.getName());
        exam.setCreatedBy(creator);
        exam.setShuffleOption(request.isShuffleOption());
        exam.setStatus(ExamStatus.WAITING);

        examRepository.save(exam);
    }

    public void updateExam(Integer examId, UpdateExamRequest request) {
        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        if (exam.getStatus() != ExamStatus.WAITING) {
            throw new AppException(ErrorCode.EXAM_CANNOT_BE_UPDATED);
        }

        exam.setName(request.getName());
        exam.setShuffleOption(request.isShuffleOption());

        examRepository.save(exam);
    }

    public void deleteExam(Integer examId) {
        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        examQuestionRepository.deleteAll(examQuestionRepository.findByExamIdOrderByOrderIndexAsc(examId));
        examParticipantRepository.deleteAll(examParticipantRepository.findByExamId(examId));
        examRepository.delete(exam);
    }

    public void addQuestion(AddQuestionToExamRequest request) {

        Exam exam = examRepository.findById(request.getExamId())
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        Question question = questionRepository.findById(request.getQuestionId())
                .orElseThrow(() -> new AppException(ErrorCode.QUESTION_NOT_FOUND));

        boolean exists = examQuestionRepository
                .findByExamIdAndQuestionId(request.getExamId(), request.getQuestionId())
                .isPresent();

        if (exists) {
            throw new AppException(ErrorCode.QUESTION_ALREADY_EXISTS);
        }

        ExamQuestion eq = new ExamQuestion();
        eq.setExam(exam);
        eq.setQuestion(question);
        eq.setOrderIndex(request.getOrderIndex());

        examQuestionRepository.save(eq);
    }

    public void removeQuestion(RemoveQuestionRequest request) {

        ExamQuestion eq = examQuestionRepository
                .findByExamIdAndQuestionId(request.getExamId(), request.getQuestionId())
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND));

        examQuestionRepository.delete(eq);
    }

    public DetailsExamResponse getExamDetail(Integer examId) {

        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        List<ExamQuestionResponse> questions =
                examQuestionRepository.findByExamIdOrderByOrderIndexAsc(examId)
                        .stream()
                        .map(eq -> {
                            var q = eq.getQuestion();

                            QuestionDetailResponse questionDto = new QuestionDetailResponse();
                            questionDto.setId(q.getId());
                            questionDto.setContent(q.getContent());
                            questionDto.setAnswer(q.getAnswer());
                            questionDto.setType(q.getType());
                            questionDto.setLevel(q.getLevel());
                            questionDto.setScore(q.getScore());
                            questionDto.setTimeLimit(q.getTimeLimit());
                            questionDto.setImageUrl(q.getImageUrl());
                            questionDto.setVideoUrl(q.getVideoUrl());

                            if (q.getCategory() != null) {
                                questionDto.setCategoryId(q.getCategory().getId());
                                questionDto.setCategoryName(q.getCategory().getName());
                            }

                            return new ExamQuestionResponse(
                                    eq.getOrderIndex(),
                                    questionDto
                            );
                        })
                        .toList();

        List<ExamParticipantResponse> participants =
                examParticipantRepository.findByExamId(examId)
                        .stream()
                        .map(ep -> new ExamParticipantResponse(
                                ep.getId(),
                                ep.getUser().getId(),
                                ep.getUser().getFullName(),
                                ep.getUser().getClasses().getClassName(),
                                ep.getStatus(),
                                ep.getScore(),
                                ep.getSeatNumber()
                        ))
                        .toList();

        return new DetailsExamResponse(
                exam.getId(),
                exam.getName(),
                exam.getStatus().name(),
                exam.getScheduledStartAt(),
                exam.getCreatedBy().getFullName(),
                exam.getCreatedAt().toString(),
                questions,
                participants
        );
    }

    public List<ExamQuestion> getExamQuestions(Integer examId) {

        return examQuestionRepository.findByExamIdOrderByOrderIndexAsc(examId);
    }

    public List<ExamParticipantResponse> getExamParticipants(Integer examId) {

        return examParticipantRepository.findByExamId(examId)
                .stream()
                .map(ep -> new ExamParticipantResponse(
                        ep.getId(),
                        ep.getUser().getId(),
                        ep.getUser().getFullName(),
                        ep.getUser().getClasses().getClassName(),
                        ep.getStatus(),
                        ep.getScore(),
                        ep.getSeatNumber()
                ))
                .toList();
    }

    public void validateUserCanJoin(ValidateJoinRequest request) {

        Exam exam = examRepository.findById(request.getExamId())
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        if (exam.getStatus() == ExamStatus.FINISHED) {
            throw new AppException(ErrorCode.EXAM_NOT_AVAILABLE);
        }

        Users user = usersRepository.findById(request.getUserId())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        if (user.getStatus() != AccountStudentStatus.ACTIVE) {
            throw new AppException(ErrorCode.USER_BLOCKED);
        }

        ExamParticipant ep = examParticipantRepository
                .findByExamIdAndUserId(request.getExamId(), request.getUserId())
                .orElseThrow(() -> new AppException(ErrorCode.NOT_INVITED));

        if (ep.getStatus() == ParticipantStatus.FINISHED) {
            throw new AppException(ErrorCode.EXAM_ALREADY_DONE);
        }

        if (exam.getStatus() == ExamStatus.WAITING) {
            return; // vào phòng chờ
        }

        if (exam.getStatus() == ExamStatus.RUNNING) {
            if (ep.getStatus() != ParticipantStatus.JOINED) {
                ep.setStatus(ParticipantStatus.JOINED);
                examParticipantRepository.save(ep);
            }
        }
    }

    public void addParticipant(AddParticipantRequest request) {

        Exam exam = examRepository.findById(request.getExamId())
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        Users user = usersRepository.findById(request.getUserId())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        if (user.getStatus() != AccountStudentStatus.ACTIVE) {
            throw new AppException(ErrorCode.USER_BLOCKED);
        }

        boolean exists = examParticipantRepository
                .findByExamIdAndUserId(request.getExamId(), request.getUserId())
                .isPresent();

        if (exists) {
            throw new AppException(ErrorCode.USER_ALREADY_INVITED);
        }

        if (exam.getStatus() == ExamStatus.RUNNING) {
            throw new AppException(ErrorCode.EXAM_ALREADY_STARTED);
        }

        if (request.getSeatNumber() != null
                && examParticipantRepository.existsByExamIdAndSeatNumber(request.getExamId(), request.getSeatNumber())) {
            throw new AppException(ErrorCode.SEAT_NUMBER_TAKEN);
        }

        ExamParticipant ep = new ExamParticipant();
        ep.setExam(exam);
        ep.setUser(user);
        ep.setStatus(ParticipantStatus.INVITED);
        ep.setScore(0);
        ep.setSeatNumber(request.getSeatNumber());

        examParticipantRepository.save(ep);
    }

    public void updateSeat(Integer examId, Integer userId, Integer seatNumber) {

        ExamParticipant ep = examParticipantRepository
                .findByExamIdAndUserId(examId, userId)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND));

        if (seatNumber != null
                && !seatNumber.equals(ep.getSeatNumber())
                && examParticipantRepository.existsByExamIdAndSeatNumber(examId, seatNumber)) {
            throw new AppException(ErrorCode.SEAT_NUMBER_TAKEN);
        }

        ep.setSeatNumber(seatNumber);
        examParticipantRepository.save(ep);
    }

    public void removeParticipant(Integer examId, Integer userId) {

        ExamParticipant ep = examParticipantRepository
                .findByExamIdAndUserId(examId, userId)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND));

        examParticipantRepository.delete(ep);
    }

    public PageResponse<ExamListResponse> getAllExams(int page, int size, String keyword) {

        Pageable pageable = PageRequest.of(page, size, Sort.by("id").descending());

        Page<Exam> exams = examRepository.search(keyword, pageable);

        List<ExamListResponse> data = exams.getContent()
                .stream()
                .map(e -> new ExamListResponse(
                        e.getId(),
                        e.getName(),
                        e.getStatus().name(),
                        e.getShuffleOption(),
                        e.getCreatedBy().getFullName(),
                        e.getCreatedAt().toString()
                ))
                .toList();

        return new PageResponse<>(
                data,
                exams.getTotalElements(),
                exams.getTotalPages(),
                page,
                size
        );
    }
}