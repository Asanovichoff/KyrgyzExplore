package com.kyrgyzexplore.notification;

import com.kyrgyzexplore.common.exception.AppException;
import com.kyrgyzexplore.notification.dto.NotificationResponse;
import com.kyrgyzexplore.push.FcmService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final FcmService fcmService;

    /**
     * Persists a notification to the DB and pushes it in real-time to the recipient's
     * personal WebSocket channel (/user/queue/notifications).
     *
     * WHY save to DB AND push via WebSocket?
     * WebSocket delivery is not guaranteed — if the user is offline, the STOMP message
     * is silently dropped. Persisting to DB means they can fetch missed notifications
     * via the REST endpoint when they reconnect.
     *
     * WHY /user/queue/notifications?
     * Spring's user-destination feature routes messages to a specific session identified
     * by the Principal set in WebSocketSecurityConfig. "/user/{username}/queue/notifications"
     * is how it's resolved internally — we just send to "/user/queue/notifications" plus
     * the username and Spring handles the routing.
     */
    @Transactional
    public void notify(UUID recipientId, NotificationType type, String title, String body, UUID bookingId) {
        Notification notification = Notification.builder()
                .recipientId(recipientId)
                .type(type)
                .title(title)
                .body(body)
                .relatedBookingId(bookingId)
                .build();

        Notification saved = notificationRepository.save(notification);
        NotificationResponse response = toResponse(saved);

        // Push real-time. convertAndSendToUser looks up the session by username (email in our case,
        // since User.getUsername() returns email and that's what the Principal name resolves to).
        try {
            messagingTemplate.convertAndSendToUser(
                    recipientId.toString(),
                    "/queue/notifications",
                    response
            );
        } catch (Exception e) {
            // WebSocket delivery failure must NOT roll back the DB transaction.
            // The notification is safely persisted — user will see it on next REST poll.
            log.warn("Failed to push real-time notification to user {}: {}", recipientId, e.getMessage());
        }

        // FCM push — reaches the user even when the app is closed.
        // FcmService is a no-op when Firebase credentials are not configured.
        fcmService.sendToUser(recipientId, title, body, type, bookingId);
    }

    @Transactional(readOnly = true)
    public Page<NotificationResponse> getMyNotifications(UUID recipientId, Pageable pageable) {
        return notificationRepository
                .findByRecipientIdOrderByCreatedAtDesc(recipientId, pageable)
                .map(this::toResponse);
    }

    @Transactional(readOnly = true)
    public int getUnreadCount(UUID recipientId) {
        return notificationRepository.countByRecipientIdAndIsReadFalse(recipientId);
    }

    @Transactional
    public void markOneAsRead(UUID notificationId, UUID recipientId) {
        Notification n = notificationRepository.findById(notificationId)
                .orElseThrow(() -> AppException.notFound("NOTIFICATION_NOT_FOUND", "Notification not found"));

        if (!n.getRecipientId().equals(recipientId)) {
            throw AppException.forbidden("NOTIFICATION_FORBIDDEN", "You cannot mark another user's notification as read");
        }

        n.setRead(true);
        notificationRepository.save(n);
    }

    @Transactional
    public int markAllAsRead(UUID recipientId) {
        return notificationRepository.markAllAsRead(recipientId);
    }

    private NotificationResponse toResponse(Notification n) {
        return NotificationResponse.builder()
                .id(n.getId())
                .recipientId(n.getRecipientId())
                .type(n.getType())
                .title(n.getTitle())
                .body(n.getBody())
                .relatedBookingId(n.getRelatedBookingId())
                .isRead(n.isRead())
                .createdAt(n.getCreatedAt())
                .build();
    }
}
