package com.kyrgyzexplore.payment;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/webhooks")
@RequiredArgsConstructor
public class StripeWebhookController {

    private final StripeWebhookService webhookService;

    /**
     * WHY byte[] instead of a parsed DTO?
     * Stripe signs the raw request body with HMAC-SHA256. If Spring deserialises
     * the JSON first (even losslessly), the byte representation changes and the
     * signature check fails. Reading the body as raw bytes preserves the exact
     * bytes Stripe signed.
     *
     * WHY always return 200?
     * Stripe retries any webhook that gets a non-2xx response for up to 3 days.
     * Unknown/unsupported event types are not errors on our side — return 200 so
     * Stripe doesn't spam us with retries for events we intentionally ignore.
     */
    @PostMapping("/stripe")
    public ResponseEntity<Void> handle(
            @RequestBody byte[] payload,
            @RequestHeader("Stripe-Signature") String sigHeader) {
        webhookService.handle(payload, sigHeader);
        return ResponseEntity.ok().build();
    }
}
