package org.example.olympic_ot_project.service;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.Core.ExamStatus;
import org.example.olympic_ot_project.enity.Exam;
import org.example.olympic_ot_project.enity.ExamQuestion;
import org.example.olympic_ot_project.enity.Question;
import org.example.olympic_ot_project.enity.Users;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.example.olympic_ot_project.repositoy.ExamQuestionRepository;
import org.example.olympic_ot_project.repositoy.ExamRepository;
import org.example.olympic_ot_project.repositoy.QuestionRepository;
import org.example.olympic_ot_project.repositoy.UsersRepository;
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

    public void createExam(String name, Integer createdById, boolean shuffleOption) {

        Users creator = usersRepository.findById(createdById)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        Exam exam = new Exam();
        exam.setName(name);
        exam.setCreatedBy(creator);
        exam.setShuffleOption(shuffleOption);
        exam.setStatus(ExamStatus.WAITING);

        examRepository.save(exam);
    }

    public void addQuestion(Integer examId, Integer questionId, Integer orderIndex) {

        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new AppException(ErrorCode.EXAM_NOT_FOUND));

        Question question = questionRepository.findById(questionId)
                .orElseThrow(() -> new AppException(ErrorCode.QUESTION_NOT_FOUND));

        ExamQuestion eq = new ExamQuestion();
        eq.setExam(exam);
        eq.setQuestion(question);
        eq.setOrderIndex(orderIndex);

        examQuestionRepository.save(eq);
    }

    public void removeQuestion(Integer examId, Integer questionId) {

        ExamQuestion eq = examQuestionRepository
                .findByExamIdAndQuestionId(examId, questionId)
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
}
