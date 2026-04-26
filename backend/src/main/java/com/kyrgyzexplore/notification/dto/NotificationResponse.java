package com.kyrgyzexplore.notification.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.kyrgyzexplore.notification.NotificationType;
import lombok.Builder;
import lombok.Getter;

import java.time.Instant;
import java.util.UUID;

@Getter
@Builder
public class NotificationResponse {
    private UUID id;
    private UUID recipientId;
    private NotificationType type;
    private String title;
    private String body;
    private UUID relatedBookingId;
    @JsonProperty("isRead")
    private boolean isRead;
    private Instant createdAt;
}
