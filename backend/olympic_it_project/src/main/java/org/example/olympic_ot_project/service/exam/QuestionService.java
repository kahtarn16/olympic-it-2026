package org.example.olympic_ot_project.service.exam;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.exam.option.CreateQuestionOptionRequest;
import org.example.olympic_ot_project.dto.exam.question.*;
import org.example.olympic_ot_project.dto.exam.option.QuestionOptionResponse;
import org.example.olympic_ot_project.dto.exam.option.UpdateQuestionOptionRequest;
import org.example.olympic_ot_project.enity.Category;
import org.example.olympic_ot_project.enity.Question;
import org.example.olympic_ot_project.enity.QuestionOption;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.example.olympic_ot_project.repositoy.CategoryRepository;
import org.example.olympic_ot_project.repositoy.QuestionOptionRepository;
import org.example.olympic_ot_project.repositoy.QuestionRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
@Transactional
public class QuestionService {
    private final QuestionRepository questionRepository;
    private final QuestionOptionRepository questionOptionRepository;
    private final CategoryRepository categoryRepository;

    public void create(CreateQuestionRequest request) {

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new AppException(ErrorCode.CATEGORY_NOT_FOUND));

        Question q = new Question();
        q.setContent(request.getContent());
        q.setType(request.getType());
        q.setLevel(request.getLevel());
        q.setImageUrl(request.getImageUrl());
        q.setVideoUrl(request.getVideoUrl());
        q.setCategory(category);

        questionRepository.save(q);
    }

    public void update(Integer id, UpdateQuestionRequest request) {

        Question q = questionRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.QUESTION_NOT_FOUND));

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new AppException(ErrorCode.CATEGORY_NOT_FOUND));

        q.setContent(request.getContent());
        q.setType(request.getType());
        q.setLevel(request.getLevel());
        q.setImageUrl(request.getImageUrl());
        q.setVideoUrl(request.getVideoUrl());
        q.setCategory(category);

        questionRepository.save(q);
    }

    public void delete(Integer id) {

        Question q = questionRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.QUESTION_NOT_FOUND));

        questionRepository.delete(q);
    }

    public QuestionPageResponse getAll(int page, int size, Integer categoryId) {

        Pageable pageable = PageRequest.of(page, size);

        Page<Question> result;

        if (categoryId != null) {
            result = questionRepository.findByCategoryId(categoryId, pageable);
        } else {
            result = questionRepository.findAll(pageable);
        }

        List<QuestionResponse> items = result.getContent()
                .stream()
                .map(this::toDTO)
                .toList();

        QuestionPageResponse res = new QuestionPageResponse();
        res.setItems(items);
        res.setPage(page);
        res.setSize(size);
        res.setTotalElements(result.getTotalElements());
        res.setTotalPages(result.getTotalPages());

        return res;
    }

    private QuestionResponse toDTO(Question q) {

        QuestionResponse dto = new QuestionResponse();

        dto.setId(q.getId());
        dto.setContent(q.getContent());
        dto.setType(q.getType());
        dto.setLevel(q.getLevel());

        if (q.getCategory() != null) {
            dto.setCategoryId(q.getCategory().getId());
            dto.setCategoryName(q.getCategory().getName());
        }

        return dto;
    }

    public void createOption(Integer questionId, CreateQuestionOptionRequest request) {

        Question question = questionRepository.findById(questionId)
                .orElseThrow(() -> new AppException(ErrorCode.QUESTION_NOT_FOUND));

        QuestionOption option = new QuestionOption();
        option.setQuestion(question);
        option.setLabel(request.getLabel());
        option.setContentText(request.getContentText());
        option.setIsCorrect(request.isCorrect());

        questionOptionRepository.save(option);
    }

    public void updateOption(Integer id, UpdateQuestionOptionRequest request) {

        QuestionOption option = questionOptionRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.OPTION_NOT_FOUND));

        option.setLabel(request.getLabel());
        option.setContentText(request.getContentText());
        option.setIsCorrect(request.isCorrect());

        questionOptionRepository.save(option);
    }

    public void deleteOption(Integer id) {

        QuestionOption option = questionOptionRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.OPTION_NOT_FOUND));

        questionOptionRepository.delete(option);
    }

    public QuestionDetailResponse getDetail(Integer id) {

        Question q = questionRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.QUESTION_NOT_FOUND));

        QuestionDetailResponse dto = new QuestionDetailResponse();
        dto.setId(q.getId());
        dto.setContent(q.getContent());
        dto.setType(q.getType());
        dto.setLevel(q.getLevel());

        if (q.getCategory() != null) {
            dto.setCategoryId(q.getCategory().getId());
            dto.setCategoryName(q.getCategory().getName());
        }

        List<QuestionOptionResponse> options = q.getOptions()
                .stream()
                .map(opt -> {
                    QuestionOptionResponse o = new QuestionOptionResponse();
                    o.setId(opt.getId());
                    o.setLabel(opt.getLabel());
                    o.setContentText(opt.getContentText());
                    o.setCorrect(opt.getIsCorrect());
                    return o;
                })
                .toList();

        dto.setOptions(options);

        return dto;
    }
}
