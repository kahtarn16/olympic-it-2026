package org.example.olympic_ot_project.exception;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum ErrorCode {
    UNCATEGORIZED_EXCEPTION(500, "Lỗi hệ thống không xác định"),
    USER_EXISTED(1001, "Người dùng đã tồn tại"),
    USER_NOT_FOUND(1002, "Không tìm thấy người dùng"),
    INVALID_OTP(1003, "Mã OTP không hợp lệ"),
    OTP_EXPIRED(1004, "Mã OTP đã hết hạn"),
    OTP_NOT_FOUND(1005, "Không tìm thấy mã OTP"),
    INVALID_CREDENTIALS(1006, "Sai tên đăng nhập hoặc mật khẩu"),
    ROLE_NOT_FOUND(1007, "Không tìm thấy role"),
    USER_ALREADY_ACTIVE(1008, "Tài khoản đã được xác nhận từ trước"),
    OTP_RESEND_TOO_FAST(1009, "Vui lòng đợi 1 phút"),
    USER_NOT_ACTIVE(1010, "Người dùng chưa xác nhận tài khoản"),
    INVALID_TOKEN(1011, "Lỗi đăng nhập"),
    TOKEN_EXPIRED(1012, "Phiên đăng nhập hết hạn, vui lòng đăng nhập lại");

    private final int code;
    private final String message;
}
