package org.example.olympic_ot_project.service.exam;

import org.example.olympic_ot_project.core.ExamState;
import org.example.olympic_ot_project.enity.ExamQuestion;
import org.example.olympic_ot_project.enity.ExamSession;
import org.example.olympic_ot_project.repositoy.ExamQuestionRepository;
import org.example.olympic_ot_project.repositoy.ExamSessionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.TaskScheduler;

import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ScheduledFuture;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ExamSessionServiceTest {

    @Mock
    private ExamSessionRepository examSessionRepository;

    @Mock
    private ExamQuestionRepository examQuestionRepository;

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    @Mock
    private TaskScheduler taskScheduler;

    @InjectMocks
    private ExamSessionService examSessionService;

    @Test
    void startExamShouldSavePreviewStateAndBroadcastEvent() {
        when(examSessionRepository.findByExamId(10)).thenReturn(Optional.empty());
        when(examQuestionRepository.findByExamIdOrderByOrderIndexAsc(10)).thenReturn(List.of(new ExamQuestion()));
        when(examSessionRepository.save(any(ExamSession.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(taskScheduler.schedule(any(Runnable.class), any(Date.class))).thenReturn(mock(ScheduledFuture.class));

        examSessionService.startExam(10);

        verify(examSessionRepository).save(any(ExamSession.class));
        verify(messagingTemplate).convertAndSend(eq("/topic/exam/10"), any());
    }
}
