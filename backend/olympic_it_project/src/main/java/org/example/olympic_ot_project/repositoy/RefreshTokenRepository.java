package org.example.olympic_ot_project.repositoy;

import org.example.olympic_ot_project.enity.RefreshToken;
import org.example.olympic_ot_project.enity.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Integer> {
    Optional<RefreshToken> findByUser(Users user);
    Optional<RefreshToken> findByRefreshToken(String refreshToken);
}
