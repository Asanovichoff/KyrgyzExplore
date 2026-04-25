package com.kyrgyzexplore.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@AllArgsConstructor
public class PaymentIntentResponse {
    private String clientSecret;    // passed to Stripe.js on the frontend to complete payment
    private String publishableKey;  // frontend needs this to initialise the Stripe SDK
    private BigDecimal amount;      // total charge in USD, for display
}
