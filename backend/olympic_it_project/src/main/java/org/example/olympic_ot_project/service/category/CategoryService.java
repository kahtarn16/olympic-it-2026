package org.example.olympic_ot_project.service.category;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.exam.category.CategoryResponse;
import org.example.olympic_ot_project.dto.exam.category.CreateCategoryRequest;
import org.example.olympic_ot_project.dto.exam.category.UpdateCategoryRequest;
import org.example.olympic_ot_project.enity.Category;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.example.olympic_ot_project.repositoy.CategoryRepository;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
@Transactional
public class CategoryService {

    private final CategoryRepository categoryRepository;

    public Category create(CreateCategoryRequest request) {

        if (categoryRepository.existsByName(request.getName())) {
            throw new AppException(ErrorCode.CATEGORY_EXISTS);
        }

        Category c = new Category();
        c.setName(request.getName());

        return categoryRepository.save(c);
    }

    public Category update(Integer id, UpdateCategoryRequest request) {

        Category c = categoryRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND));

        if (categoryRepository.existsByName(request.getName())) {
            throw new AppException(ErrorCode.CATEGORY_EXISTS);
        }

        c.setName(request.getName());

        return categoryRepository.save(c);
    }

    public void delete(Integer id) {

        Category c = categoryRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND));

        categoryRepository.delete(c);
    }

    public List<CategoryResponse> getAll() {
        return categoryRepository.findAll()
                .stream()
                .map(this::toDTO)
                .toList();
    }

    public CategoryResponse toDTO(Category c) {
        CategoryResponse dto = new CategoryResponse();
        dto.setId(c.getId());
        dto.setName(c.getName());
        return dto;
    }
}
