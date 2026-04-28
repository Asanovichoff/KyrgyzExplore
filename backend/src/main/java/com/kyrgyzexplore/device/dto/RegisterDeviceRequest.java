package com.kyrgyzexplore.device.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class RegisterDeviceRequest {

    @NotBlank(message = "token is required")
    private String token;

    @NotBlank(message = "platform is required")
    @Pattern(regexp = "android|ios", message = "platform must be 'android' or 'ios'")
    private String platform;
}
