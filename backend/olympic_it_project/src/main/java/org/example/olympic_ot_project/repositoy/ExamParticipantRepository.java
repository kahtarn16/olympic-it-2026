package org.example.olympic_ot_project.repositoy;

import org.example.olympic_ot_project.core.ParticipantStatus;
import org.example.olympic_ot_project.enity.ExamParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ExamParticipantRepository extends JpaRepository<ExamParticipant, Integer> {
    Optional<ExamParticipant> findByExamIdAndUserId(Integer examId, Integer userId);
    List<ExamParticipant> findByExamId(Integer examId);
    @Query("""
    SELECT ep FROM ExamParticipant ep
    JOIN FETCH ep.exam e
    WHERE ep.user.id = :userId
""")
    List<ExamParticipant> findMyExams(Integer userId);

    Boolean existsByExamIdAndUser_Username(Integer examId, String username);

    List<ExamParticipant> findByExamIdAndStatus(Integer examId, Enum status);
    boolean existsByExamIdAndUser_UsernameAndStatusNot(Integer examId, String username, ParticipantStatus status);
}
