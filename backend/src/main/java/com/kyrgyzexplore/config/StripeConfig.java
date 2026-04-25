package com.kyrgyzexplore.config;

import com.stripe.Stripe;
import jakarta.annotation.PostConstruct;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Binds the stripe.* properties from application.yml and initialises the
 * Stripe SDK global API key once at startup. Every Stripe SDK call made
 * anywhere in the app automatically uses this key.
 */
@Configuration
@ConfigurationProperties(prefix = "stripe")
@Getter
@Setter
public class StripeConfig {

    private String secretKey;
    private String webhookSecret;
    private String publishableKey;
    private int platformFeePercent;

    @PostConstruct
    public void init() {
        Stripe.apiKey = secretKey;
    }
}
