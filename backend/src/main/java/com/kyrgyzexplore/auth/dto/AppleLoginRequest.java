package com.kyrgyzexplore.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

@Getter
public class AppleLoginRequest {

    @NotBlank
    private String identityToken;
}
