package com.kyrgyzexplore.payment;

import com.kyrgyzexplore.booking.BookingService;
import com.stripe.model.Event;
import com.stripe.model.PaymentIntent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class StripeWebhookService {

    private final PaymentService paymentService;
    private final BookingService bookingService;

    public void handle(byte[] payload, String sigHeader) {
        Event event = paymentService.constructWebhookEvent(payload, sigHeader);
        log.debug("Received Stripe event: {}", event.getType());

        switch (event.getType()) {
            case "payment_intent.succeeded" -> handlePaymentSucceeded(event);
            default -> log.debug("Unhandled Stripe event type: {}", event.getType());
        }
    }

    @SuppressWarnings("deprecation")
    private void handlePaymentSucceeded(Event event) {
        // getObject() (versioned) returns empty when the SDK's bundled API version
        // doesn't match the event's API version. getData().getObject() (deprecated)
        // is the intentional fallback — it skips the version check, which is exactly
        // what we want here. We only need the `id` field, which is stable across versions.
        String paymentIntentId = event.getDataObjectDeserializer()
                .getObject()
                .map(obj -> ((PaymentIntent) obj).getId())
                .orElseGet(() -> ((PaymentIntent) event.getData().getObject()).getId());

        bookingService.markPaid(paymentIntentId);
    }
}
