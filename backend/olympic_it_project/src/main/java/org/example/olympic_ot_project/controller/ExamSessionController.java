package org.example.olympic_ot_project.controller;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.dto.ApiResponse;
import org.example.olympic_ot_project.dto.exam.*;
import org.example.olympic_ot_project.dto.exam.websocket.SubmitAnswerPayload;
import org.example.olympic_ot_project.service.exam.ExamService;
import org.example.olympic_ot_project.service.exam.ExamSessionService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/exam-session")
@RequiredArgsConstructor
public class ExamSessionController {
    private final ExamSessionService examSessionService;

    @PostMapping("/{examId}/room")
    public void createRoom(@PathVariable Integer examId) {
        examSessionService.createRoom(examId);
    }

    @PostMapping("/{examId}/start")
    public void startExam(@PathVariable Integer examId) {
        examSessionService.startExam(examId);
    }

    @PostMapping("/{examId}/next")
    public void nextQuestion(@PathVariable Integer examId) {
        examSessionService.adminNextQuestion(examId);
    }

    @PostMapping("/{examId}/submit")
    public SubmitAnswerResponse submitAnswer(
            @PathVariable Integer examId,
            @RequestBody SubmitAnswerPayload payload
    ) {
        return examSessionService.submitAnswer(examId, payload);
    }

    @GetMapping("/{examId}")
    public ExamSessionResponse getSession(@PathVariable Integer examId) {
        return examSessionService.getSessionInfo(examId);
    }

    @GetMapping("/{examId}/leaderboard")
    public List<Leaderboard> leaderboard(@PathVariable Integer examId) {
        return examSessionService.getLeaderboard(examId);
    }

    @GetMapping("/{examId}/restore")
    public ExamRestoreResponse restore(@PathVariable Integer examId) {
        return examSessionService.restoreExam(examId);
    }

    @PostMapping("/{examId}/reset")
    public void reset(@PathVariable Integer examId) {
        examSessionService.resetExam(examId);
    }

    @GetMapping("/{examId}/admin-restore")
    public ExamRestoreResponse adminRestore(@PathVariable Integer examId) {
        return examSessionService.getAdminSessionDetail(examId);
    }

    @PostMapping("/{examId}/participants/{userId}/unban")
    public void unbanParticipant(
            @PathVariable Integer examId,
            @PathVariable Integer userId
    ) {
        examSessionService.unbanParticipant(examId, userId);
    }

    @PostMapping("/{examId}/schedule")
    public void scheduleAutoStart(@PathVariable Integer examId, @RequestBody ScheduleExamRequest request) {
        examSessionService.scheduleAutoStart(examId, request.getStartAt());
    }

    @DeleteMapping("/{examId}/schedule")
    public void cancelSchedule(@PathVariable Integer examId) {
        examSessionService.cancelAutoStart(examId);
    }

    @PostMapping("/{examId}/regrade")
    public void regradeAnswers(
            @PathVariable Integer examId,
            @RequestBody AdminRegradeRequest request
    ) {
        examSessionService.adminRegradeAnswers(examId, request);
    }

}