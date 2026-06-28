package org.example.olympic_ot_project.dto.student;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateStudentRequest {
    @NotBlank(message = "Tên đăng nhập không được để trống")
    @Size(min = 10, max = 100, message = "Tên đăng nhập phải từ 10 ký tự trở lên")
    private String username;
    @NotBlank(message = "Mật khẩu không được để trống")
    @Size(min = 6, max = 100, message = "Mật khẩu phải từ 6 ký tự trở lên")
    private String password;
    @NotBlank(message = "Email không được để trống")
    @Email(message = "Email không đúng định dạng")
    private String email;
    @NotBlank(message = "Họ và tên không được để trống")
    @Size(min = 8 , message = "Họ và tên phải từ 8 ký tự đổ lên")
    private String fullName;
    @NotNull(message = "Lớp không được để trống")
    private Integer classId;
}
