package org.example.olympic_ot_project.service.exam;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.config.StorageProperties;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.URI;
import java.nio.file.*;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FileStorageService {

    private final StorageProperties storageProperties;

    public String uploadImage(MultipartFile file) {

        if (file == null || file.isEmpty()) {
            throw new AppException(ErrorCode.FILE_EMPTY);
        }

        String contentType = file.getContentType();

        if (contentType == null || !contentType.startsWith("image/")) {
            throw new AppException(ErrorCode.INVALID_IMAGE_FILE);
        }

        return save(file, "images");
    }

    public String uploadVideo(MultipartFile file) {

        if (file == null || file.isEmpty()) {
            throw new AppException(ErrorCode.FILE_EMPTY);
        }

        String contentType = file.getContentType();

        if (contentType == null || !contentType.startsWith("video/")) {
            throw new AppException(ErrorCode.INVALID_VIDEO_FILE);
        }

        return save(file, "videos");
    }

    private String save(MultipartFile file, String folderName) {

        try {

            String fileName =
                    UUID.randomUUID() + "_" + file.getOriginalFilename();

            Path folder =
                    Paths.get(storageProperties.getLocation(), folderName);

            Files.createDirectories(folder);

            Path target = folder.resolve(fileName);

            Files.copy(file.getInputStream(),
                    target,
                    StandardCopyOption.REPLACE_EXISTING);

            return "/uploads/" + folderName + "/" + fileName;

        } catch (IOException e) {

            throw new RuntimeException(e);
        }
    }

    public void deleteFile(String url) {
        if (url == null || url.isBlank()) {
            return;
        }
        try {
            String path = url;
            if (path.startsWith("http://") || path.startsWith("https://")) {
                path = URI.create(path).getPath();
            }
            path = path.replace('\\', '/');

            int uploadsIndex = path.indexOf("/uploads/");
            if (uploadsIndex >= 0) {
                path = path.substring(uploadsIndex + "/uploads/".length());
            }

            Path root = Paths.get(storageProperties.getLocation()).toAbsolutePath().normalize();
            Path targetPath = Paths.get(path);
            Path file = targetPath.isAbsolute()
                    ? targetPath.normalize()
                    : root.resolve(targetPath).normalize();

            if (!file.startsWith(root)) {
                return;
            }

            try {
                Files.deleteIfExists(file);
            } catch (IOException ignored) {
                // Ignore delete failures for invalid/missing files during cleanup.
            }
        } catch (Exception ignored) {
            // Ignore invalid URLs or parse errors while attempting cleanup.
        }
    }

}
