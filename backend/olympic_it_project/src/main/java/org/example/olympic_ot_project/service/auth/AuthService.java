package org.example.olympic_ot_project.service.auth;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.auth.forgotpassword.ForgotPasswordRequest;
import org.example.olympic_ot_project.dto.auth.forgotpassword.ResetPasswordRequest;
import org.example.olympic_ot_project.dto.auth.login.LoginRequest;
import org.example.olympic_ot_project.dto.auth.register.OtpRequest;
import org.example.olympic_ot_project.dto.auth.register.RegisterRequest;
import org.example.olympic_ot_project.dto.auth.register.ResendRequest;
import org.example.olympic_ot_project.enity.ActiveEmail;
import org.example.olympic_ot_project.enity.Users;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.example.olympic_ot_project.repositoy.ActiveEmailRepository;
import org.example.olympic_ot_project.repositoy.RoleRepository;
import org.example.olympic_ot_project.repositoy.UsersRepository;
import org.example.olympic_ot_project.service.mailsender.EmailService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Random;

@Service
@Transactional
@RequiredArgsConstructor
public class AuthService {
    private final UsersRepository usersRepository;
    private final ActiveEmailRepository activeEmailRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final RoleRepository roleRepository;
    private final CustomUserDetailsService customUserDetailsService;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final RedisTemplate<String, String> redisTemplate;

    public void register(RegisterRequest request) {
        if (usersRepository.findByUsername(request.getUsername()).isPresent()) {
            throw new AppException(ErrorCode.USER_EXISTED);
        }

        if(usersRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new AppException(ErrorCode.USER_EXISTED);
        }

        Users user = new Users();
        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setIsActive(false);
        user.setCreatedAt(LocalDateTime.now());
        user.setRole(roleRepository.findById(2)
                .orElseThrow(() -> new AppException(ErrorCode.ROLE_NOT_FOUND)));

        usersRepository.save(user);

        String otp = String.format("%06d", new Random().nextInt(1000000));

        ActiveEmail activeEmail = new ActiveEmail();
        activeEmail.setUser(user);
        activeEmail.setOtpCode(otp);
        activeEmail.setExpiredAt(LocalDateTime.now().plusMinutes(5));

        activeEmailRepository.save(activeEmail);

        emailService.sendOtpEmail(user.getEmail(), otp);
    }

    public void verifyOtp(OtpRequest request) {
        Users user = usersRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        ActiveEmail activeEmail = activeEmailRepository.findByUser(user)
                .orElseThrow(() -> new AppException(ErrorCode.OTP_NOT_FOUND));

        if (activeEmail.getExpiredAt().isBefore(LocalDateTime.now())) {
            activeEmailRepository.delete(activeEmail);
            throw new AppException(ErrorCode.OTP_EXPIRED);
        }

        if (request.getOtpCode() == null || !activeEmail.getOtpCode().equals(request.getOtpCode())) {
            throw new AppException(ErrorCode.INVALID_OTP);
        }

        user.setIsActive(true);
        usersRepository.save(user);

        activeEmailRepository.delete(activeEmail);
    }

    public void resendOtp(ResendRequest request) {
        Users user = usersRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        if (Boolean.TRUE.equals(user.getIsActive())) {
            throw new AppException(ErrorCode.USER_ALREADY_ACTIVE);
        }

        activeEmailRepository.findByUser(user).ifPresent(activeEmail -> {
            if (activeEmail.getExpiredAt().isAfter(LocalDateTime.now().plusMinutes(4))) {
                throw new AppException(ErrorCode.OTP_RESEND_TOO_FAST);
            }
            activeEmailRepository.delete(activeEmail);
        });

        String otp = String.format("%06d", new Random().nextInt(1000000));

        ActiveEmail activeEmail = new ActiveEmail();
        activeEmail.setUser(user);
        activeEmail.setOtpCode(otp);
        activeEmail.setExpiredAt(LocalDateTime.now().plusMinutes(5));
        activeEmailRepository.save(activeEmail);

        emailService.sendOtpEmail(user.getEmail(), otp);
    }

    public void forgotPassword(ForgotPasswordRequest request) {
        Users user = usersRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        activeEmailRepository.findByUser(user).ifPresent(activeEmailRepository::delete);

        String otp = String.format("%06d", new Random().nextInt(1000000));

        ActiveEmail activeEmail = new ActiveEmail();
        activeEmail.setUser(user);
        activeEmail.setOtpCode(otp);
        activeEmail.setExpiredAt(LocalDateTime.now().plusMinutes(5));
        activeEmailRepository.save(activeEmail);

        emailService.sendResetPasswordEmail(user.getEmail(), otp);
    }

    public void resetPassword(ResetPasswordRequest request) {
        Users user = usersRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        ActiveEmail activeEmail = activeEmailRepository.findByUser(user)
                .orElseThrow(() -> new AppException(ErrorCode.OTP_NOT_FOUND));

        if (activeEmail.getExpiredAt().isBefore(LocalDateTime.now())) {
            activeEmailRepository.delete(activeEmail);
            throw new AppException(ErrorCode.OTP_EXPIRED);
        }

        if (!activeEmail.getOtpCode().equals(request.getOtpCode())) {
            throw new AppException(ErrorCode.INVALID_OTP);
        }

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        usersRepository.save(user);

        activeEmailRepository.delete(activeEmail);
    }

    public String login(LoginRequest request) {
        Users user = usersRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        if (Boolean.FALSE.equals(user.getIsActive())) {
            throw new AppException(ErrorCode.USER_NOT_ACTIVE);
        }
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword())
        );

        UserDetails userDetails = customUserDetailsService.loadUserByUsername(request.getUsername());
        return jwtService.genericToken(userDetails);
    }

    public void logout(String token) {
        long expiration = jwtService.extractAllClaims(token).getExpiration().getTime();
        long now = System.currentTimeMillis();
        long ttl = (expiration - now) / 1000;

        if (ttl > 0) {
            redisTemplate.opsForValue().set("blacklist:" + token, "true", Duration.ofSeconds(ttl));
        }
    }
}
