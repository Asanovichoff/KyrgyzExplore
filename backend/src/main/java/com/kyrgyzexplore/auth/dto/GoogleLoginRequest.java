package com.kyrgyzexplore.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class GoogleLoginRequest {

    /**
     * The ID token returned by the Google Sign-In SDK on the client.
     * The backend verifies this with Google's tokeninfo endpoint before
     * trusting the email/name it contains.
     */
    @NotBlank(message = "idToken is required")
    private String idToken;
}