package org.example.olympic_ot_project.controller;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.exam.question.UploadResponse;
import org.example.olympic_ot_project.service.exam.FileStorageService;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/upload")
public class UploadController {

    private final FileStorageService fileStorageService;

    @PostMapping("/image")
    public UploadResponse uploadImage(
            @RequestParam("file") MultipartFile file
    ) {

        String url = fileStorageService.uploadImage(file);

        return new UploadResponse(url);
    }

    @PostMapping("/video")
    public UploadResponse uploadVideo(
            @RequestParam("file") MultipartFile file
    ) {

        String url = fileStorageService.uploadVideo(file);

        return new UploadResponse(url);
    }
}