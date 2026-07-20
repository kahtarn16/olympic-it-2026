package org.example.olympic_ot_project.service.mailsender;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;

@Service
public class EmailService {
    @Autowired
    private JavaMailSender javaMailSender;

    @Async("taskExecutor")
    public void sendOtpEmail(String toEmail, String otp) {
        String subject = "Xác thực tài khoản Olympic IT";
        String content = "Chào bạn,\n\nĐây là mã OTP để kích hoạt tài khoản: " + otp +
                "\nMã này có hiệu lực trong 5 phút.";
        sendEmail(toEmail, subject, content);
    }

    @Async("taskExecutor")
    public void sendResetPasswordEmail(String toEmail, String otp) {
        String subject = "Yêu cầu đặt lại mật khẩu";
        String content = "Chào bạn,\n\nĐây là mã OTP để xác nhận cài đặt lại mật khẩu: " + otp +
                "\nMã này có hiệu lực trong 5 phút.";
        sendEmail(toEmail, subject, content);
    }

    public void sendEmail(String to, String subject, String content) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(to);
            message.setSubject(subject);
            message.setText(content);
            javaMailSender.send(message);
            System.out.println("Gửi mail thành công tới: " + to);
        } catch (Exception e) {
            System.err.println("Lỗi khi gửi mail tới " + to + ": " + e.getMessage());
        }
    }
}
