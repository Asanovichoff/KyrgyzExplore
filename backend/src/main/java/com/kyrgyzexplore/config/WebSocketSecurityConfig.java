package com.kyrgyzexplore.config;

import com.kyrgyzexplore.auth.JwtService;
import com.kyrgyzexplore.user.User;
import com.kyrgyzexplore.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import java.util.UUID;

/**
 * Validates the JWT on every STOMP CONNECT frame and sets the user principal.
 *
 * WHY validate here instead of in the HTTP handshake?
 * The WebSocket HTTP upgrade request (/ws) must be permitAll() in SecurityConfig because
 * mobile clients send the JWT in the STOMP CONNECT frame, not in the HTTP headers.
 * The HTTP layer never sees the token — only the STOMP layer does.
 *
 * IMPORTANT: JwtService uses UUID as the subject (not email).
 * - jwtService.extractUserId(token) → UUID
 * - jwtService.isTokenValid(token)  → boolean  (no UserDetails parameter needed)
 * The Principal name is set to the UUID string, which is what WebSocketMessageController
 * reads via principal.getName().
 *
 * WHY set the principal to the UsernamePasswordAuthenticationToken?
 * Spring's user-destination feature (/user/queue/...) routes messages by Principal.getName().
 * Setting a proper Authentication object also gives Spring Security context if needed later.
 */
@Slf4j
@Configuration
@RequiredArgsConstructor
@EnableWebSocketMessageBroker
public class WebSocketSecurityConfig implements WebSocketMessageBrokerConfigurer {

    private final JwtService jwtService;
    private final UserRepository userRepository;

    @Override
    public void configureClientInboundChannel(
            org.springframework.messaging.simp.config.ChannelRegistration registration) {

        registration.interceptors(new ChannelInterceptor() {
            @Override
            public Message<?> preSend(Message<?> message, MessageChannel channel) {
                StompHeaderAccessor accessor =
                        MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

                if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
                    String authHeader = accessor.getFirstNativeHeader("Authorization");
                    if (authHeader != null && authHeader.startsWith("Bearer ")) {
                        String token = authHeader.substring(7);

                        if (jwtService.isTokenValid(token)) {
                            UUID userId = jwtService.extractUserId(token);
                            User user = userRepository.findById(userId).orElse(null);

                            if (user != null) {
                                UsernamePasswordAuthenticationToken auth =
                                        new UsernamePasswordAuthenticationToken(
                                                user, null, user.getAuthorities());
                                accessor.setUser(auth);
                            } else {
                                log.warn("WebSocket CONNECT: JWT valid but user {} not found", userId);
                            }
                        } else {
                            log.debug("WebSocket CONNECT: invalid or expired JWT");
                        }
                    }
                }
                return message;
            }
        });
    }
}
