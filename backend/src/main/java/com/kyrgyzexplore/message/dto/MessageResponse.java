package com.kyrgyzexplore.message.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Getter;

import java.time.Instant;
import java.util.UUID;

@Getter
@Builder
public class MessageResponse {
    private UUID id;
    private UUID bookingId;
    private UUID senderId;
    private String senderName;
    private String content;
    @JsonProperty("isRead")
    private boolean isRead;
    private Instant createdAt;
}
