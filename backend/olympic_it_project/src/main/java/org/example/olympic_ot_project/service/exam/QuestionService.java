package org.example.olympic_ot_project.service.exam;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.core.QuestionType;
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
    private final FileStorageService fileStorageService;

    private void validateQuestionMedia(
            QuestionType type,
            String imageUrl,
            String videoUrl
    ) {
        boolean hasImage = imageUrl != null && !imageUrl.isBlank();
        boolean hasVideo = videoUrl != null && !videoUrl.isBlank();

        if (hasImage && hasVideo) {
            throw new AppException(ErrorCode.INVALID_MEDIA_SELECTION);
        }

        switch (type) {
            case MCQ_TEXT -> {
                if (hasImage || hasVideo) {
                    throw new AppException(ErrorCode.MCQ_TEXT_CANNOT_HAVE_MEDIA);
                }
            }
            case MCQ_MEDIA -> {
                if (!hasImage && !hasVideo) {
                    throw new AppException(ErrorCode.MEDIA_REQUIRED);
                }
            }
            case ESSAY_TEXT -> {
                if (hasImage || hasVideo) {
                    throw new AppException(ErrorCode.ESSAY_TEXT_CANNOT_HAVE_MEDIA);
                }
            }
            case ESSAY_MEDIA -> {
                if (!hasImage && !hasVideo) {
                    throw new AppException(ErrorCode.MEDIA_REQUIRED);
                }
            }
        }
    }

    private void validateQuestionOptions(
            QuestionType type,
            String answer,
            List<CreateQuestionOptionRequest> options
    ) {
        if (type == QuestionType.ESSAY_TEXT || type == QuestionType.ESSAY_MEDIA) {
            if (answer == null || answer.isBlank()) {
                throw new AppException(ErrorCode.ANSWER_REQUIRED);
            }
            if (options != null && !options.isEmpty()) {
                throw new AppException(ErrorCode.ESSAY_DOES_NOT_HAVE_OPTION);
            }
            return;
        }

        if (options == null || options.size() != 4) {
            throw new AppException(ErrorCode.MCQ_MUST_HAVE_FOUR_OPTIONS);
        }

        long correctCount = options.stream()
                .filter(CreateQuestionOptionRequest::getIsCorrect)
                .count();
        if (correctCount != 1) {
            throw new AppException(ErrorCode.MCQ_MUST_HAVE_ONE_CORRECT_OPTION);
        }

        boolean hasImageOption = options.stream()
                .anyMatch(opt -> opt.getImageUrl() != null && !opt.getImageUrl().isBlank());
        boolean hasTextOption = options.stream()
                .anyMatch(opt -> opt.getContentText() != null && !opt.getContentText().isBlank());

        if (hasImageOption && hasTextOption) {
            throw new AppException(ErrorCode.MCQ_OPTION_TYPE_INCONSISTENT);
        }
        if (!hasImageOption && !hasTextOption) {
            throw new AppException(ErrorCode.MCQ_OPTION_EMPTY);
        }

        if (hasImageOption) {
            options.forEach(opt -> {
                if (opt.getImageUrl() == null || opt.getImageUrl().isBlank()) {
                    throw new AppException(ErrorCode.MCQ_OPTION_IMAGE_REQUIRED);
                }
            });
        } else {
            options.forEach(opt -> {
                if (opt.getContentText() == null || opt.getContentText().isBlank()) {
                    throw new AppException(ErrorCode.MCQ_OPTION_TEXT_REQUIRED);
                }
            });
        }
    }

    public void create(CreateQuestionRequest request) {
        validateQuestionMedia(request.getType(), request.getImageUrl(), request.getVideoUrl());
        validateQuestionOptions(request.getType(), request.getAnswer(), request.getOptions());

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new AppException(ErrorCode.CATEGORY_NOT_FOUND));

        Question q = new Question();
        q.setContent(request.getContent());
        q.setType(request.getType());
        q.setCategory(category);
        q.setLevel(request.getLevel());
        q.setAnswer(request.getAnswer());
        q.setScore(request.getScore());
        q.setImageUrl(request.getImageUrl());
        q.setTimeLimit(request.getTimeLimit());
        q.setVideoUrl(request.getVideoUrl());
        questionRepository.save(q);

        if (request.getOptions() != null && !request.getOptions().isEmpty()) {
            for (var optReq : request.getOptions()) {
                questionOptionRepository.save(optReq.toEntity(q));
            }
        }
    }

    public void update(Integer id, UpdateQuestionRequest request) {
        validateQuestionMedia(request.getType(), request.getImageUrl(), request.getVideoUrl());
        validateQuestionOptions(request.getType(), request.getAnswer(), request.getOptions());

        Question q = questionRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.QUESTION_NOT_FOUND));
        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new AppException(ErrorCode.CATEGORY_NOT_FOUND));

        String oldImage = q.getImageUrl();
        String oldVideo = q.getVideoUrl();

        q.setContent(request.getContent());
        q.setType(request.getType());
        q.setLevel(request.getLevel());
        q.setAnswer(request.getAnswer());
        q.setScore(request.getScore());
        q.setImageUrl(request.getImageUrl());
        q.setTimeLimit(request.getTimeLimit());
        q.setVideoUrl(request.getVideoUrl());
        q.setCategory(category);
        questionRepository.save(q);

        List<QuestionOption> oldOptions = questionOptionRepository.findByQuestionId(id);
        oldOptions.forEach(opt -> {
            if (opt.getImageUrl() != null && !opt.getImageUrl().isBlank()) {
                fileStorageService.deleteFile(opt.getImageUrl());
            }
        });
        questionOptionRepository.deleteByQuestionId(id);

        if (request.getOptions() != null && !request.getOptions().isEmpty()) {
            for (var optReq : request.getOptions()) {
                questionOptionRepository.save(optReq.toEntity(q));
            }
        }

        if (oldImage != null && !oldImage.equals(request.getImageUrl())) {
            fileStorageService.deleteFile(oldImage);
        }
        if (oldVideo != null && !oldVideo.equals(request.getVideoUrl())) {
            fileStorageService.deleteFile(oldVideo);
        }
    }

    public void delete(Integer id) {
        Question q = questionRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.QUESTION_NOT_FOUND));

        List<QuestionOption> oldOptions = questionOptionRepository.findByQuestionId(id);
        oldOptions.forEach(opt -> {
            if (opt.getImageUrl() != null && !opt.getImageUrl().isBlank()) {
                fileStorageService.deleteFile(opt.getImageUrl());
            }
        });
        questionOptionRepository.deleteByQuestionId(id);

        fileStorageService.deleteFile(q.getImageUrl());
        fileStorageService.deleteFile(q.getVideoUrl());
        questionRepository.delete(q);
    }

    public QuestionPageResponse getAll(int page, int size, Integer categoryId) {

        Pageable pageable = PageRequest.of(page, size);

        Page<Question> result;

        if (categoryId == null) {
            result = questionRepository.findAll(pageable);
        } else {
            result = questionRepository.findByCategoryId(categoryId, pageable);
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
        dto.setTimeLimit(q.getTimeLimit());

        dto.setScore(q.getScore());
        dto.setImageUrl(q.getImageUrl());
        dto.setVideoUrl(q.getVideoUrl());

        if (q.getCategory() != null) {
            dto.setCategoryId(q.getCategory().getId());
            dto.setCategoryName(q.getCategory().getName());
        }

        return dto;
    }

    public void createOption(Integer questionId, CreateQuestionOptionRequest request) {

        Question question = questionRepository.findById(questionId)
                .orElseThrow(() -> new AppException(ErrorCode.QUESTION_NOT_FOUND));

        if (question.getType() == QuestionType.ESSAY_TEXT
                || question.getType() == QuestionType.ESSAY_MEDIA) {
            throw new AppException(ErrorCode.ESSAY_DOES_NOT_HAVE_OPTION);
        }

        QuestionOption option = new QuestionOption();
        option.setQuestion(question);
        option.setLabel(request.getLabel());
        option.setContentText(request.getContentText());
        option.setImageUrl(request.getImageUrl());
        option.setIsCorrect(request.getIsCorrect());

        questionOptionRepository.save(option);
    }

    public void updateOption(Integer id, UpdateQuestionOptionRequest request) {

        QuestionOption option = questionOptionRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.OPTION_NOT_FOUND));

        if (option.getQuestion().getType() == QuestionType.ESSAY_TEXT
                || option.getQuestion().getType() == QuestionType.ESSAY_MEDIA) {
            throw new AppException(ErrorCode.ESSAY_DOES_NOT_HAVE_OPTION);
        }

        String oldImage = option.getImageUrl();

        option.setLabel(request.getLabel());
        option.setContentText(request.getContentText());
        option.setImageUrl(request.getImageUrl());
        option.setIsCorrect(request.getIsCorrect());

        questionOptionRepository.save(option);

        if (oldImage != null && !oldImage.equals(request.getImageUrl())) {
            fileStorageService.deleteFile(oldImage);
        }
    }

    public void deleteOption(Integer id) {

        QuestionOption option = questionOptionRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.OPTION_NOT_FOUND));

        fileStorageService.deleteFile(option.getImageUrl());

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
        dto.setTimeLimit(q.getTimeLimit());

        dto.setAnswer(q.getAnswer());
        dto.setScore(q.getScore());
        dto.setImageUrl(q.getImageUrl());
        dto.setVideoUrl(q.getVideoUrl());

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
                    o.setIsCorrect(opt.getIsCorrect());
                    o.setImageUrl(opt.getImageUrl());
                    return o;
                })
                .toList();

        dto.setOptions(options);

        return dto;
    }
}
