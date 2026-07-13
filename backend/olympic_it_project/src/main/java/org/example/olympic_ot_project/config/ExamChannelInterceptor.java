package org.example.olympic_ot_project.config;

import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.core.ParticipantStatus;
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
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null) {
            return message;
        }
        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            String authHeader = accessor.getFirstNativeHeader("Authorization");

            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                String token = authHeader.substring(7);
                try {
                    Boolean blacklisted = redisTemplate.hasKey("blacklist:" + token);
                    if (Boolean.TRUE.equals(blacklisted)) {
                        return null;
                    }

                    Claims claims = jwtService.extractAllClaims(token);
                    String username = claims.getSubject();
                    String role = claims.get("role", String.class);

                    if (role == null || role.isBlank()) {
                        return null;
                    }

                    role = role.trim().toUpperCase();
                    if (!role.startsWith("ROLE_")) {
                        role = "ROLE_" + role;
                    }

                    List<GrantedAuthority> authorities = List.of(new SimpleGrantedAuthority(role));

                    if (username != null) {
                        UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                        UsernamePasswordAuthenticationToken auth =
                                new UsernamePasswordAuthenticationToken(
                                        userDetails,
                                        null,
                                        authorities
                                );

                        accessor.setUser(auth);

                        SecurityContextHolder.getContext().setAuthentication(auth);

                    }
                } catch (Exception e) {
                    return null;
                }
            } else {
                return null;
            }
        }

        if (!StompCommand.SUBSCRIBE.equals(accessor.getCommand())) {
            return message;
        }

        String destination = accessor.getDestination();

        if (destination == null || !destination.startsWith("/topic/exam/")) {
            return message;
        }

        Principal principal = accessor.getUser();

        if (principal == null) {
            return null;
        }

        String username = principal.getName();

        Integer examId;
        try {
            examId = Integer.parseInt(destination.split("/")[3]);
        } catch (Exception e) {
            return null;
        }

        boolean isAdmin = false;
        boolean isUser = false;

        if (principal instanceof org.springframework.security.core.Authentication auth) {
            isAdmin = auth.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

            isUser = auth.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_USER"));
        }

        if (isAdmin) {
            System.out.println("👑 [ADMIN] " + username + " đã subscribe theo dõi phòng thi ID: " + examId);
            return message;
        }
        if (isUser) {
            boolean allowed = examParticipantRepository
                    .existsByExamIdAndUser_UsernameAndStatusNot(
                            examId, username, ParticipantStatus.BANNED
                    );

            if (!allowed) {
                return null;
            }
            return message;
        }
        return null;
    }
}