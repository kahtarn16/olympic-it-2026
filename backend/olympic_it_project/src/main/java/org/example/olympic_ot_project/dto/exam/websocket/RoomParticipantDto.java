package org.example.olympic_ot_project.dto.exam.websocket;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoomParticipantDto {
    private Integer userId;
    private String fullName;
    private String className;
    private Integer seatNumber;
}