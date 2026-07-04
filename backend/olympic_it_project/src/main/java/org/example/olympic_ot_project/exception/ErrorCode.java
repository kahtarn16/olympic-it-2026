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
    CLASS_NAME_EXISTS(1029, "Lớp này đã có trong khóa học"),
    CLASSES_NOT_FOUND(1014, "Không tìm thấy lớp"),
    CLASSES_HAS_STUDENTS(1013, "Lớp này đã có sinh viên, không được phép xóa"),
    USERNAME_USED(1014, "Tên đăng nhập đã được sử dụng"),
    EMAIL_USED(1015, "Email này đã được sử dụng"),
    ROLE_NOT_FOUND(1016, "Không tìm thấy role"),
    CANNOT_DELETE_ACADEMIC_YEAR_HAS_CLASSES(1016, "Không thể xóa khóa học vì đang có lớp trong khóa học này"),
    EXAM_NOT_FOUND(1017, "Không tìm thấy cuộc thi"),
    QUESTION_NOT_FOUND(1018, "Không tìm thấy câu hỏi"),
    NOT_FOUND(1019, "Không tìm thấy"),
    USER_ALREADY_INVITED(1020, "Thí sinh đã được thêm từ trước"),
    USER_BLOCKED(1021, "Tài khoản thí sinh đã bị khóa"),
    NOT_INVITED(1022, "Thí sinh không được mời tham gia"),
    EXAM_ALREADY_DONE(1023, "Cuộc thi đã được hoàn thành"),
    EXAM_NOT_AVAILABLE(1024, "Cuộc thi không khả dụng"),
    EXAM_ALREADY_STARTED(1025, "Cuộc thi đã bắt đầu"),
    OPTION_NOT_FOUND(1026, "Không tìm thấy câu trả lời"),
    CATEGORY_EXISTS(1027, "Đã có thể loại câu hỏi này"),
    CATEGORY_NOT_FOUND(1028, "Không tìm thấy thể loại câu hỏi"),
    USER_ALREADY_WITH_CLASS(1030, "Thí sinh đã có mặt ở lớp này"),
    MCQ_TEXT_CANNOT_HAVE_MEDIA(1031, "Không được phép chứa hình ảnh"),
    MEDIA_REQUIRED(1032, "Câu hỏi yêu cầu hình ảnh"),
    ESSAY_TEXT_CANNOT_HAVE_MEDIA(1033, "Không được phép chứa hình ảnh"),
    ESSAY_DOES_NOT_HAVE_OPTION(1034, "Câu hỏi tự luận không được phép có đáp án lựa chọn"),
    FILE_EMPTY(1035, "File không được để trống"),
    INVALID_IMAGE_FILE(1036, "File phải là hình ảnh"),
    INVALID_VIDEO_FILE(1037, "File phải là video"),
    INVALID_FILE(1038, "Đường dẫn không hợp lệ"),
    INVALID_MEDIA_SELECTION(1039, "Chỉ được chọn 1 ảnh hoặc 1 video"),
    QUESTION_QUESTION_NOT_FOUND(1040, "Không tìm thấy câu trả lời"),
    ANSWER_REQUIRED(1041, "Yêu cầu câu trả lời"),
    MCQ_MUST_HAVE_FOUR_OPTIONS(1042, "Trắc nghiệm cần có 4 đáp án"),
    MCQ_MUST_HAVE_ONE_CORRECT_OPTION(1043, "Cần 1 câu trả lời đúng"),
    MCQ_OPTION_TYPE_INCONSISTENT(1044, "MCQ_OPTION_TYPE_INCONSISTENT"),
    MCQ_OPTION_EMPTY(1045, "Không được phép bỏ trống câu trả lời"),
    MCQ_OPTION_IMAGE_REQUIRED(1046, "Yêu cầu hình ảnh cho tùy chọn câu hỏi trắc nghiệm"),
    MCQ_OPTION_TEXT_REQUIRED(1047, "Bắt buộc nhập nội dung cho tùy chọn câu hỏi trắc nghiệm.");

    private final int code;
    private final String message;
}
