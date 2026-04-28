package com.kyrgyzexplore.device;

import com.kyrgyzexplore.common.dto.ApiResponse;
import com.kyrgyzexplore.device.dto.RegisterDeviceRequest;
import com.kyrgyzexplore.user.User;
import jakarta.validation.Valid;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.constraints.NotBlank;

@RestController
@RequestMapping("/api/v1/devices")
@RequiredArgsConstructor
@Validated
public class DeviceTokenController {

    private final DeviceTokenRepository deviceTokenRepository;

    /**
     * Upsert: if the token already exists (same device, different user after re-login),
     * update its user_id so notifications go to the current user. If new, insert it.
     *
     * WHY upsert instead of just insert?
     * FCM tokens are tied to the device, not the account. If Alice logs out and Bob logs
     * in on the same phone, the FCM token stays the same. Without upsert, Alice keeps
     * receiving Bob's push notifications until the token is manually cleaned up.
     */
    @PostMapping("/token")
    @Transactional
    public ApiResponse<Void> registerToken(
            @RequestBody @Valid RegisterDeviceRequest req,
            @AuthenticationPrincipal User currentUser) {

        deviceTokenRepository.findByToken(req.getToken())
                .ifPresentOrElse(
                        existing -> existing.setUserId(currentUser.getId()),
                        () -> deviceTokenRepository.save(DeviceToken.builder()
                                .userId(currentUser.getId())
                                .token(req.getToken())
                                .platform(req.getPlatform())
                                .build())
                );

        return ApiResponse.ok(null);
    }

    @DeleteMapping("/token")
    @Transactional
    public ApiResponse<Void> unregisterToken(
            @RequestBody @Valid DeleteTokenRequest req,
            @AuthenticationPrincipal User currentUser) {

        deviceTokenRepository.findByToken(req.getToken())
                .filter(dt -> dt.getUserId().equals(currentUser.getId()))
                .ifPresent(dt -> deviceTokenRepository.deleteByToken(req.getToken()));

        return ApiResponse.ok(null);
    }

    @Getter
    @NoArgsConstructor
    static class DeleteTokenRequest {
        @NotBlank(message = "token is required")
        private String token;
    }
}
