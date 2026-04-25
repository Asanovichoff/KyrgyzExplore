package com.kyrgyzexplore.payment;

import com.kyrgyzexplore.common.exception.AppException;
import com.kyrgyzexplore.config.StripeConfig;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import com.stripe.model.Event;
import com.stripe.model.PaymentIntent;
import com.stripe.net.Webhook;
import com.stripe.param.PaymentIntentCreateParams;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentService {

    private final StripeConfig stripeConfig;

    /**
     * Creates a Stripe PaymentIntent for the given booking amount.
     *
     * WHY USD instead of KGS?
     * Stripe does not support KGS (Kyrgyz Som) as a currency. USD is used as a
     * stand-in for development and testing. When a local payment gateway that
     * supports KGS is integrated (e.g. Elsom, MBank), this method will be replaced.
     *
     * WHY convert to cents?
     * Stripe amounts are always in the smallest currency unit. $75.00 USD → 7500 cents.
     */
    public PaymentIntent createPaymentIntent(BigDecimal amount, UUID bookingId) {
        long amountInCents = amount.multiply(BigDecimal.valueOf(100)).longValue();
        // allow_redirects=NEVER: we only want card payments for mobile.
        // Without this, Stripe enables redirect-based methods (Klarna, etc.) which
        // require a return_url and don't work in the standard card flow.
        PaymentIntentCreateParams params = PaymentIntentCreateParams.builder()
                .setAmount(amountInCents)
                .setCurrency("usd")
                .setAutomaticPaymentMethods(
                        PaymentIntentCreateParams.AutomaticPaymentMethods.builder()
                                .setEnabled(true)
                                .setAllowRedirects(PaymentIntentCreateParams.AutomaticPaymentMethods.AllowRedirects.NEVER)
                                .build()
                )
                .putMetadata("bookingId", bookingId.toString())
                .build();
        try {
            return PaymentIntent.create(params);
        } catch (StripeException e) {
            log.error("Failed to create PaymentIntent for booking {}: {}", bookingId, e.getMessage());
            throw AppException.internalServerError("STRIPE_ERROR", "Payment could not be initiated");
        }
    }

    /**
     * Verifies the Stripe webhook signature and parses the event.
     * MUST receive the raw request bytes — do NOT pass a parsed/re-serialised body.
     * Stripe computes the signature over the exact bytes it sent; any modification breaks it.
     */
    public Event constructWebhookEvent(byte[] payload, String sigHeader) {
        try {
            return Webhook.constructEvent(new String(payload), sigHeader, stripeConfig.getWebhookSecret());
        } catch (SignatureVerificationException e) {
            throw AppException.badRequest("INVALID_WEBHOOK_SIGNATURE", "Webhook signature verification failed");
        }
    }
}
