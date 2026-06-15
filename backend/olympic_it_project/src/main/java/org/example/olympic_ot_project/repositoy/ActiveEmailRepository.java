package org.example.olympic_ot_project.repositoy;

import org.example.olympic_ot_project.enity.ActiveEmail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ActiveEmailRepository extends JpaRepository<ActiveEmail, Integer> {

}
