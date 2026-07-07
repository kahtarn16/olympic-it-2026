package org.example.olympic_ot_project.repositoy;

import org.example.olympic_ot_project.enity.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UsersRepository extends JpaRepository<Users, Integer> {
    Optional<Users> findByUsername(String username);
    Optional<Users> findByEmail(String email);
    Boolean existsByUsername(String username);
    boolean existsByEmail(String email);
    List<Users> findByRole_Id(Integer roleId);
    @Query("""
    SELECT u FROM Users u
    JOIN FETCH u.classes c
    JOIN FETCH c.academicYear
    WHERE u.id = :id
""")
    Optional<Users> findMe(Integer id);
}
