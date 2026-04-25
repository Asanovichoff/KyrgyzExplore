package com.kyrgyzexplore.user.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class ConnectStatusResponse {
    private String accountId;
    private boolean chargesEnabled;   // true once Stripe onboarding is fully complete
    private boolean detailsSubmitted; // true once the host has submitted their info to Stripe
}
