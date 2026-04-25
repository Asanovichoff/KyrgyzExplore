package com.kyrgyzexplore.user;

import com.kyrgyzexplore.common.exception.AppException;
import com.kyrgyzexplore.user.dto.ConnectStatusResponse;
import com.stripe.exception.StripeException;
import com.stripe.model.Account;
import com.stripe.model.AccountLink;
import com.stripe.param.AccountCreateParams;
import com.stripe.param.AccountLinkCreateParams;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {

    private final UserRepository userRepository;

    @Value("${stripe.publishable-key}")
    private String publishableKey; // unused here but confirms Stripe is configured

    /**
     * Creates a Stripe Connect Express account for the host (or retrieves an existing one)
     * and returns a one-time onboarding URL the host must visit to complete their Stripe profile.
     *
     * WHY Express (not Standard or Custom)?
     * - Standard: Stripe hosts the full dashboard — complex for our users
     * - Custom: We own the full onboarding UX — too much work for Phase 6
     * - Express: Stripe hosts a lightweight onboarding flow, we keep control of branding
     *
     * WHY generate a new AccountLink every time?
     * AccountLinks expire after ~5 minutes and are single-use. Re-calling this endpoint
     * always generates a fresh link, which is the correct approach for both first-time
     * onboarding and re-onboarding (if the host didn't finish the first time).
     */
    @Transactional
    public String createConnectOnboardingUrl(UUID hostId) {
        User host = userRepository.findById(hostId)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "User not found"));

        try {
            String accountId = host.getStripeAccountId();

            if (accountId == null) {
                Account account = Account.create(AccountCreateParams.builder()
                        .setType(AccountCreateParams.Type.EXPRESS)
                        .setCountry("KG")
                        .build());
                accountId = account.getId();
                host.setStripeAccountId(accountId);
                userRepository.save(host);
            }

            AccountLink link = AccountLink.create(AccountLinkCreateParams.builder()
                    .setAccount(accountId)
                    .setType(AccountLinkCreateParams.Type.ACCOUNT_ONBOARDING)
                    // TODO: replace with real frontend URLs in production
                    .setRefreshUrl("https://kyrgyzexplore.com/host/connect/refresh")
                    .setReturnUrl("https://kyrgyzexplore.com/host/connect/complete")
                    .build());

            return link.getUrl();

        } catch (StripeException e) {
            log.error("Failed to create Connect account for host {}: {}", hostId, e.getMessage());
            throw AppException.internalServerError("STRIPE_ERROR", "Could not create payout account");
        }
    }

    /**
     * Returns the current Stripe Connect onboarding status for a host.
     * chargesEnabled = true means the host can receive payouts.
     */
    public ConnectStatusResponse getConnectStatus(UUID hostId) {
        User host = userRepository.findById(hostId)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "User not found"));

        if (host.getStripeAccountId() == null) {
            return new ConnectStatusResponse(null, false, false);
        }

        try {
            Account account = Account.retrieve(host.getStripeAccountId());
            return new ConnectStatusResponse(
                    account.getId(),
                    Boolean.TRUE.equals(account.getChargesEnabled()),
                    Boolean.TRUE.equals(account.getDetailsSubmitted())
            );
        } catch (StripeException e) {
            log.error("Failed to retrieve Connect status for host {}: {}", hostId, e.getMessage());
            throw AppException.internalServerError("STRIPE_ERROR", "Could not retrieve payout account status");
        }
    }
}
