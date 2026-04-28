package com.kyrgyzexplore.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Binds the sendgrid.* properties from application.yml.
 *
 * WHY no @PostConstruct (unlike StripeConfig)?
 * The Stripe SDK has a global static `Stripe.apiKey` that must be set once at startup.
 * The SendGrid SDK is stateless — you pass the API key every time you create a SendGrid
 * instance. There is nothing to initialise at startup, so @PostConstruct is not needed.
 *
 * WHY isConfigured()?
 * In dev, the API key is a placeholder ("SG.REPLACE_ME"). Rather than crash or send real
 * emails to real addresses during development, EmailService checks isConfigured() and logs
 * a debug message instead. Same graceful-skip pattern as FirebaseConfig.
 */
@Configuration
@ConfigurationProperties(prefix = "sendgrid")
@Getter
@Setter
public class SendGridConfig {

    private String apiKey;
    private String fromAddress;
    private String fromName;

    public boolean isConfigured() {
        return apiKey != null && !apiKey.isBlank() && !apiKey.startsWith("SG.REPLACE");
    }
}
