package org.example.olympic_ot_project.repositoy;

import org.example.olympic_ot_project.enity.OtpEmail;
import org.example.olympic_ot_project.enity.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OtpEmailRepository extends JpaRepository<OtpEmail, Integer> {
    Optional<OtpEmail> findByUser(Users user);
}
