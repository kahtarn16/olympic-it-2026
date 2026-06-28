package org.example.olympic_ot_project.exception;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum ErrorCode {
    UNCATEGORIZED_EXCEPTION(500, "Lỗi hệ thống không xác định"),
    USER_NOT_FOUND(1002, "Không tìm thấy người dùng"),
    INVALID_OTP(1003, "Mã OTP không hợp lệ"),
    OTP_EXPIRED(1004, "Mã OTP đã hết hạn"),
    OTP_NOT_FOUND(1005, "Không tìm thấy mã OTP"),
    OTP_RESEND_TOO_FAST(1009, "Vui lòng đợi 1 phút"),
    USER_LOCKED(1010, "Tài khoản này đã bị khóa"),
    INVALID_TOKEN(1011, "Lỗi đăng nhập"),
    TOKEN_EXPIRED(1012, "Phiên đăng nhập hết hạn, vui lòng đăng nhập lại"),
    ACADEMIC_YEAR_USED(1012, "Khóa học đã được thêm"),
    ACADEMIC_YEAR_NOT_FOUND(1013, "Không tìm thấy khóa học"),
    CLASSES_USED(1013, "Tên lớp đã được sử dụng"),
    CLASSES_NOT_FOUND(1014, "Không tìm thấy lớp"),
    CLASSES_HAS_STUDENTS(1013, "Lớp này đã có sinh viên, không được phép xóa"),
    USERNAME_USED(1014, "Tên đăng nhập đã được sử dụng"),
    EMAIL_USED(1015, "Email này đã được sử dụng"),
    ROLE_NOT_FOUND(1016, "Không tìm thấy role");

    private final int code;
    private final String message;
}
