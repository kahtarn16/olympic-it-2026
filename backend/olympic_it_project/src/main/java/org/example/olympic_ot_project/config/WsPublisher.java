package org.example.olympic_ot_project.config;

import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class WsPublisher {

    private final SimpMessagingTemplate template;

    public void send(Integer examId, Object data) {
        template.convertAndSend("/topic/exam/" + examId, data);
    }

    public void leaderboard(Integer examId, Object data) {
        template.convertAndSend("/topic/exam/" + examId + "/leaderboard", data);
    }
}