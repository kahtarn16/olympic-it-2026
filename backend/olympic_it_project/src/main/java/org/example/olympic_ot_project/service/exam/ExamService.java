package org.example.olympic_ot_project.service.exam;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.Core.AccountStudentStatus;
import org.example.olympic_ot_project.Core.ExamStatus;
import org.example.olympic_ot_project.Core.ParticipantStatus;
import org.example.olympic_ot_project.dto.exam.*;
import org.example.olympic_ot_project.dto.exam.question.RemoveQuestionRequest;
import org.example.olympic_ot_project.enity.*;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.example.olympic_ot_project.repositoy.*;
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

    public void addQuestion(AddQuestionToExamRequest request) {

        Exam exam = examRepository.findById(request.getExamId())
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        Question question = questionRepository.findById(request.getQuestionId())
                .orElseThrow(() -> new AppException(ErrorCode.QUESTION_NOT_FOUND));

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

    public void startExam(Integer examId) {

        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        exam.setStatus(ExamStatus.RUNNING);

        examRepository.save(exam);
    }

    public Exam getExamDetail(Integer examId) {

        return examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));
    }

    public List<ExamQuestion> getExamQuestions(Integer examId) {

        return examQuestionRepository.findByExamIdOrderByOrderIndexAsc(examId);
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

        ExamParticipant ep = new ExamParticipant();
        ep.setExam(exam);
        ep.setUser(user);
        ep.setStatus(ParticipantStatus.INVITED);
        ep.setScore(0);

        examParticipantRepository.save(ep);
    }
}
