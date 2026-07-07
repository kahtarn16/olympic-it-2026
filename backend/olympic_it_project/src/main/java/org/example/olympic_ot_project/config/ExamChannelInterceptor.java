package org.example.olympic_ot_project.config;

import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.repositoy.ExamParticipantRepository;
import org.example.olympic_ot_project.service.auth.CustomUserDetailsService;
import org.example.olympic_ot_project.service.auth.JwtService;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.*;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.security.Principal;
import java.util.List;

@Component
@RequiredArgsConstructor
public class ExamChannelInterceptor implements ChannelInterceptor {

    private final ExamParticipantRepository examParticipantRepository;
    private final JwtService jwtService;
    private final CustomUserDetailsService userDetailsService;
    private final RedisTemplate<String, String> redisTemplate;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {

        // Lấy Accessor chuẩn của Spring để thao tác trực tiếp trên Header gốc
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null) {
            return message;
        }

        // =======================================================
        // 1. GIAI ĐOẠN CONNECT: BÓC TÁCH JWT & ĐỒNG BỘ DANH TÍNH
        // =======================================================
        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            String authHeader = accessor.getFirstNativeHeader("Authorization");

            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                String token = authHeader.substring(7);
                try {
                    // Kiểm tra token xem có nằm trong Blacklist của Redis không
                    Boolean blacklisted = redisTemplate.hasKey("blacklist:" + token);
                    if (Boolean.TRUE.equals(blacklisted)) {
                        System.err.println("❌ [WebSocket Auth] Token đã bị thu hồi (Blacklisted)!");
                        return null; // Chặn kết nối dứt khoát
                    }

                    // Giải mã Claims từ JwtService của bạn
                    Claims claims = jwtService.extractAllClaims(token);
                    String username = claims.getSubject();
                    String role = claims.get("role", String.class);

                    if (role == null || role.isBlank()) {
                        System.err.println("❌ [WebSocket Auth] Token thiếu claim 'role'!");
                        return null;
                    }

                    // Chuẩn hóa định dạng Role y hệt JwtFilter của bạn
                    role = role.trim().toUpperCase();
                    if (!role.startsWith("ROLE_")) {
                        role = "ROLE_" + role;
                    }

                    List<GrantedAuthority> authorities = List.of(new SimpleGrantedAuthority(role));

                    if (username != null) {
                        // Tải thông tin chi tiết của User
                        UserDetails userDetails = userDetailsService.loadUserByUsername(username);

                        // Tạo đối tượng Authentication với danh sách authorities chuẩn hóa
                        UsernamePasswordAuthenticationToken auth =
                                new UsernamePasswordAuthenticationToken(
                                        userDetails,
                                        null,
                                        authorities // Sử dụng authorities bóc tách từ Token
                                );

                        // Nạp User vào WebSocket Session để các công đoạn sau (SUBSCRIBE) lấy ra dùng
                        accessor.setUser(auth);

                        // Đồng bộ thêm vào SecurityContext cho thread hiện tại
                        SecurityContextHolder.getContext().setAuthentication(auth);

                        System.out.println("⚡ [WebSocket Auth] Đăng nhập thành công cho: " + username + " [" + role + "]");
                    }
                } catch (Exception e) {
                    System.err.println("❌ [WebSocket Auth] Token lỏ hoặc hết hạn: " + e.getMessage());
                    return null; // Token sai -> Không cho kết nối
                }
            } else {
                System.err.println("❌ [WebSocket Auth] Từ chối kết nối do không tìm thấy Bearer Token!");
                return null; // Không gửi kèm token -> Chặn luôn
            }
        }

        // =======================================================
        // 2. GIAI ĐOẠN SUBSCRIBE: PHÂN QUYỀN VÀO PHÒNG THI
        // =======================================================
        if (!StompCommand.SUBSCRIBE.equals(accessor.getCommand())) {
            return message;
        }

        String destination = accessor.getDestination();

        if (destination == null || !destination.startsWith("/topic/exam/")) {
            return message;
        }

        // Lấy thông tin Principal đã nạp từ bước CONNECT
        Principal principal = accessor.getUser();

        if (principal == null) {
            System.err.println("❌ [WebSocket Security] Từ chối SUBSCRIBE: Không tìm thấy Principal (Chưa xác thực)");
            return null; // Chặn subscribe
        }

        String username = principal.getName();

        // Tiến hành bóc tách lấy examId từ đường dẫn /topic/exam/{examId}
        Integer examId;
        try {
            examId = Integer.parseInt(destination.split("/")[3]);
        } catch (Exception e) {
            System.err.println("❌ [WebSocket Security] Đường dẫn destination không hợp lệ: " + destination);
            return null;
        }

        boolean isAdmin = false;
        boolean isUser = false;

        // Ép kiểu về Authentication để quét danh sách Quyền hạn (Authorities)
        if (principal instanceof org.springframework.security.core.Authentication auth) {
            isAdmin = auth.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

            isUser = auth.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_USER"));
        }

        // ✔️ Nếu là ADMIN: Cho phép lắng nghe cập nhật của mọi phòng thi
        if (isAdmin) {
            System.out.println("👑 [ADMIN] " + username + " đã subscribe theo dõi phòng thi ID: " + examId);
            return message;
        }

        // ✔️ Nếu là USER: Bắt buộc phải là thí sinh (participant) hợp lệ của kỳ thi đó
        if (isUser) {
            boolean allowed = examParticipantRepository
                    .existsByExamIdAndUser_Username(examId, username);

            if (!allowed) {
                System.err.println("❌ [BỊ CHẶN] Thí sinh " + username + " không có trong danh sách phòng thi ID: " + examId);
                return null; // Trả về null để chặn nhận tin từ topic này, không gây crash
            }

            System.out.println("🎯 [THÍ SINH] " + username + " đã kết nối vào phòng thi ID: " + examId);
            return message;
        }

        // ❌ Mọi trường hợp Role khác không được định nghĩa -> Chặn
        System.err.println("❌ [BỊ CHẶN] User " + username + " có quyền hạn không hợp lệ!");
        return null;
    }
}