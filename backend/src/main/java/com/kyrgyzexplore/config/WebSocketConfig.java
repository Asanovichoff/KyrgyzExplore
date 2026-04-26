package com.kyrgyzexplore.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * Sets up the STOMP message broker that powers real-time chat and notifications.
 *
 * HOW STOMP OVER WEBSOCKET WORKS (plain-English):
 * 1. Client opens a WebSocket connection to /ws (the "handshake" endpoint).
 * 2. Client sends a STOMP CONNECT frame — this is where we validate the JWT (see WebSocketSecurityConfig).
 * 3. Client subscribes to topics (/topic/booking/123) or personal queues (/user/queue/notifications).
 * 4. When a message is sent to a topic, ALL current subscribers receive it.
 * 5. Personal queues (/user/...) route only to the specific user's session.
 *
 * WHY no SockJS?
 * SockJS is a fallback for browsers that don't support WebSocket (rare today).
 * Our clients are native mobile apps — they always speak native WebSocket. No SockJS needed.
 *
 * WHY enableSimpleBroker (not a full message broker like RabbitMQ)?
 * The simple in-memory broker is fine for a single server. If we scale to multiple
 * instances, we'd switch to a full broker (RabbitMQ/Redis) so all instances share state.
 * That's a future concern — simple broker keeps the stack lean for now.
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws").setAllowedOriginPatterns("*");
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        // /topic: broadcast channels (many subscribers)
        // /queue: point-to-point (used with /user prefix for personal notifications)
        registry.enableSimpleBroker("/topic", "/queue");

        // /app: prefix for messages handled by @MessageMapping methods
        registry.setApplicationDestinationPrefixes("/app");

        // /user: Spring resolves /user/{username}/queue/... to the right session
        registry.setUserDestinationPrefix("/user");
    }
}
