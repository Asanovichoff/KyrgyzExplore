package com.kyrgyzexplore.push;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.*;
import com.kyrgyzexplore.device.DeviceToken;
import com.kyrgyzexplore.device.DeviceTokenRepository;
import com.kyrgyzexplore.notification.NotificationType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class FcmService {

    private final DeviceTokenRepository deviceTokenRepository;

    /**
     * Sends an FCM push to every device the user has registered.
     *
     * WHY check FirebaseApp.getApps().isEmpty()?
     * FirebaseConfig skips initialization when credentials are placeholders.
     * This guard prevents NullPointerException when calling
     * FirebaseMessaging.getInstance() on an uninitialised SDK.
     *
     * WHY delete UNREGISTERED / INVALID_ARGUMENT tokens?
     * UNREGISTERED means the user uninstalled the app — the token is permanently dead.
     * INVALID_ARGUMENT means the token format is wrong (usually a test/fake token).
     * Keeping them wastes API calls on every future notification.
     */
    @Transactional
    public void sendToUser(UUID userId, String title, String body,
                           NotificationType type, UUID bookingId) {

        if (FirebaseApp.getApps().isEmpty()) {
            log.debug("FCM skipped — Firebase not configured");
            return;
        }

        List<DeviceToken> tokens = deviceTokenRepository.findByUserId(userId);
        if (tokens.isEmpty()) return;

        for (DeviceToken dt : tokens) {
            try {
                Message message = Message.builder()
                        .setNotification(Notification.builder()
                                .setTitle(title)
                                .setBody(body)
                                .build())
                        .putData("type", type.name())
                        .putData("bookingId", bookingId != null ? bookingId.toString() : "")
                        .setToken(dt.getToken())
                        .build();

                FirebaseMessaging.getInstance().send(message);
                log.debug("FCM sent to user {} device {}", userId, dt.getToken());

            } catch (FirebaseMessagingException e) {
                MessagingErrorCode code = e.getMessagingErrorCode();
                if (code == MessagingErrorCode.UNREGISTERED
                        || code == MessagingErrorCode.INVALID_ARGUMENT) {
                    log.info("Removing stale FCM token for user {}: {}", userId, e.getMessage());
                    deviceTokenRepository.deleteByToken(dt.getToken());
                } else {
                    log.warn("FCM send failed for user {} token {}: {}", userId, dt.getToken(), e.getMessage());
                }
            }
        }
    }
}
