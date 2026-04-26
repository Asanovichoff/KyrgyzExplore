package com.kyrgyzexplore.message;

import com.kyrgyzexplore.message.dto.SendMessageRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.util.UUID;

/**
 * Handles inbound STOMP messages from clients.
 *
 * WHY @Controller instead of @RestController?
 * @MessageMapping is part of Spring WebSocket/STOMP — it doesn't return HTTP responses.
 * @RestController adds @ResponseBody which is meaningless here. Use plain @Controller.
 *
 * Flow:
 *   Client sends to /app/chat/{bookingId} (the /app prefix is configured in WebSocketConfig)
 *   → Spring routes to handleMessage()
 *   → MessageService saves + broadcasts to /topic/booking/{bookingId}
 *
 * The Principal is set by WebSocketSecurityConfig when the STOMP CONNECT frame is validated.
 * Its name is the user's UUID string (since JWT subject = userId).
 */
@Controller
@RequiredArgsConstructor
public class WebSocketMessageController {

    private final MessageService messageService;

    @MessageMapping("/chat/{bookingId}")
    public void handleMessage(
            @DestinationVariable UUID bookingId,
            @Valid @Payload SendMessageRequest request,
            Principal principal) {

        // principal.getName() returns the UUID string we set as the JWT subject
        UUID senderId = UUID.fromString(principal.getName());
        messageService.send(bookingId, senderId, request.getContent());

        // MessageService already broadcasts to /topic/booking/{bookingId} via SimpMessagingTemplate.
        // We return void here intentionally — Spring would broadcast to the topic again if we returned
        // a value and used @SendTo, which would duplicate the message.
    }
}
