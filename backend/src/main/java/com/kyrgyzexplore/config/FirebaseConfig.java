package com.kyrgyzexplore.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.Getter;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.io.ByteArrayInputStream;
import java.util.Base64;

/**
 * Initialises the Firebase Admin SDK once at startup using a base64-encoded
 * service-account JSON from environment variables.
 *
 * WHY base64-encode the JSON?
 * Service-account JSON is a multi-line file with quotes and special characters.
 * Embedding it directly in a .env file would require shell escaping. Encoding it
 * as a single base64 string makes it a safe, single-line environment variable.
 *
 * WHY check for "REPLACE" prefix?
 * In dev, .env.example ships with placeholder values like "REPLACE_ME".
 * We want the app to start and run without real Firebase credentials — FCM is
 * just disabled. This check avoids a confusing Base64/JSON parse error.
 */
@Configuration
@ConfigurationProperties(prefix = "firebase")
@Getter
@Setter
@Slf4j
public class FirebaseConfig {

    private String projectId;
    private String serviceAccountJsonBase64;

    @PostConstruct
    public void init() {
        if (serviceAccountJsonBase64 == null
                || serviceAccountJsonBase64.isBlank()
                || serviceAccountJsonBase64.startsWith("REPLACE")) {
            log.warn("Firebase not configured — push notifications disabled. " +
                     "Set FIREBASE_PROJECT_ID and FIREBASE_SERVICE_ACCOUNT_JSON_BASE64 in .env to enable.");
            return;
        }

        try {
            byte[] decoded = Base64.getDecoder().decode(serviceAccountJsonBase64);
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(new ByteArrayInputStream(decoded)))
                    .setProjectId(projectId)
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                log.info("Firebase initialized for project: {}", projectId);
            }
        } catch (Exception e) {
            log.error("Failed to initialize Firebase — push notifications disabled: {}", e.getMessage());
        }
    }
}
