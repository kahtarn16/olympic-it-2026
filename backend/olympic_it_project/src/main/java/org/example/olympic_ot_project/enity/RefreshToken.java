package org.example.olympic_ot_project.enity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "refresh_token")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RefreshToken {
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Id
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private Users user;

    @Column(name = "refresh_token", nullable = false, unique = true, length = 500)
    private  String refreshToken;

    @Column(name = "expired_at", nullable = false)
    private LocalDateTime expiredAt;
}
