package org.example.olympic_ot_project.service.auth;

import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.core.AccountStudentStatus;
import org.example.olympic_ot_project.dto.auth.forgotpassword.ForgotPasswordRequest;
import org.example.olympic_ot_project.dto.auth.forgotpassword.ResetPasswordRequest;
import org.example.olympic_ot_project.dto.auth.login.LoginRequest;
import org.example.olympic_ot_project.dto.auth.login.LoginResponse;
import org.example.olympic_ot_project.dto.auth.forgotpassword.ResendRequest;
import org.example.olympic_ot_project.enity.OtpEmail;
import org.example.olympic_ot_project.enity.RefreshToken;
import org.example.olympic_ot_project.enity.Users;
import org.example.olympic_ot_project.exception.AppException;
import org.example.olympic_ot_project.exception.ErrorCode;
import org.example.olympic_ot_project.repositoy.OtpEmailRepository;
import org.example.olympic_ot_project.repositoy.RefreshTokenRepository;
import org.example.olympic_ot_project.repositoy.RoleRepository;
import org.example.olympic_ot_project.repositoy.UsersRepository;
import org.example.olympic_ot_project.service.mailsender.EmailService;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Date;
import java.util.Optional;
import java.util.Random;

@Service
@Transactional
@RequiredArgsConstructor
public class AuthService {
    private final UsersRepository usersRepository;
    private final OtpEmailRepository otpEmailRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final RoleRepository roleRepository;
    private final CustomUserDetailsService customUserDetailsService;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final RedisTemplate<String, String> redisTemplate;
    private final RefreshTokenRepository refreshTokenRepository;

    public void resendOtp(ResendRequest request) {
        Users user = usersRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        if (user.getStatus() == AccountStudentStatus.LOCKED) {
            throw new AppException(ErrorCode.USER_LOCKED);
        }

        otpEmailRepository.findByUser(user).ifPresent(otpEmail -> {
            if (otpEmail.getExpiredAt().isAfter(LocalDateTime.now().plusMinutes(4))) {
                throw new AppException(ErrorCode.OTP_RESEND_TOO_FAST);
            }
            otpEmailRepository.delete(otpEmail);
        });

        String otp = String.format("%06d", new Random().nextInt(1000000));

        OtpEmail otpEmail = new OtpEmail();
        otpEmail.setUser(user);
        otpEmail.setOtpCode(otp);
        otpEmail.setExpiredAt(LocalDateTime.now().plusMinutes(5));
        otpEmailRepository.save(otpEmail);

        emailService.sendOtpEmail(user.getEmail(), otp);
    }

    public void forgotPassword(ForgotPasswordRequest request) {
        Users user = usersRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        otpEmailRepository.findByUser(user).ifPresent(otpEmailRepository::delete);

        String otp = String.format("%06d", new Random().nextInt(1000000));

        OtpEmail otpEmail = new OtpEmail();
        otpEmail.setUser(user);
        otpEmail.setOtpCode(otp);
        otpEmail.setExpiredAt(LocalDateTime.now().plusMinutes(5));
        otpEmailRepository.save(otpEmail);

        emailService.sendResetPasswordEmail(user.getEmail(), otp);
    }

    public void resetPassword(ResetPasswordRequest request) {
        Users user = usersRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        OtpEmail otpEmail = otpEmailRepository.findByUser(user)
                .orElseThrow(() -> new AppException(ErrorCode.OTP_NOT_FOUND));

        if (otpEmail.getExpiredAt().isBefore(LocalDateTime.now())) {
            otpEmailRepository.delete(otpEmail);
            throw new AppException(ErrorCode.OTP_EXPIRED);
        }

        if (!otpEmail.getOtpCode().equals(request.getOtpCode())) {
            throw new AppException(ErrorCode.INVALID_OTP);
        }

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        usersRepository.save(user);

        otpEmailRepository.delete(otpEmail);
    }

    public LoginResponse login(LoginRequest request) {
        Users user = usersRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        if (user.getStatus() != AccountStudentStatus.ACTIVE) {
            throw new AppException(ErrorCode.USER_LOCKED);
        }

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getUsername(),
                        request.getPassword()
                )
        );

        UserDetails userDetails = customUserDetailsService.loadUserByUsername(user.getUsername());
        String accessToken = jwtService.genericToken(userDetails);

        String refreshTokenValue = java.util.UUID.randomUUID().toString();

        refreshTokenRepository.findByUser(user)
                .ifPresent(refreshTokenRepository::delete);

        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .refreshToken(refreshTokenValue)
                .expiredAt(LocalDateTime.now().plusDays(7))
                .build();

        refreshTokenRepository.save(refreshToken);

        return new LoginResponse(accessToken, refreshTokenValue, user.getRole().getRoleName(), user.getId());
    }

    public void logout(String token) {

        Claims claims = jwtService.extractAllClaims(token);
        String username = claims.getSubject();

        Users user = usersRepository.findByUsername(username)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        refreshTokenRepository.findByUser(user)
                .ifPresent(refreshTokenRepository::delete);

        Date expiration = claims.getExpiration();
        long ttl = expiration.getTime() - System.currentTimeMillis();

        if (ttl > 0) {
            redisTemplate.opsForValue()
                    .set("blacklist:" + token,
                            "true",
                            ttl,
                            java.util.concurrent.TimeUnit.MILLISECONDS);
        }
    }

    public LoginResponse refreshToken(String refreshTokenValue) {
        System.out.println("INPUT TOKEN=[" + refreshTokenValue + "]");

        RefreshToken rfToken = refreshTokenRepository.findByRefreshToken(refreshTokenValue)
                .orElseThrow(() -> new AppException(ErrorCode.INVALID_TOKEN));


        Optional<RefreshToken> optional =
                refreshTokenRepository.findByRefreshToken(refreshTokenValue);

        System.out.println("FOUND = " + optional.isPresent());

        RefreshToken s = optional
                .orElseThrow(() -> new AppException(ErrorCode.INVALID_TOKEN));

        System.out.println("TOKEN ID = " + s.getId());

        Users user = rfToken.getUser();

        if (user.getStatus() == AccountStudentStatus.LOCKED) {
            throw new AppException(ErrorCode.USER_LOCKED);
        }

        if (rfToken.getExpiredAt().isBefore(LocalDateTime.now())) {
            refreshTokenRepository.delete(rfToken);
            throw new AppException(ErrorCode.TOKEN_EXPIRED);
        }

        UserDetails userDetails =
                customUserDetailsService.loadUserByUsername(user.getUsername());

        String accessToken = jwtService.genericToken(userDetails);

        return new LoginResponse(
                accessToken,
                rfToken.getRefreshToken(),
                user.getRole().getRoleName(),
                user.getId()
        );
    }
}
