package com.kyrgyzexplore.user;

import com.kyrgyzexplore.common.dto.ApiResponse;
import com.kyrgyzexplore.common.exception.AppException;
import com.kyrgyzexplore.listing.S3Service;
import com.kyrgyzexplore.user.dto.ConnectStatusResponse;
import com.kyrgyzexplore.user.dto.UpdateUserRequest;
import com.kyrgyzexplore.user.dto.UserResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;
    private final UserService userService;
    private final S3Service s3Service;

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserResponse>> getMe(
            @AuthenticationPrincipal User currentUser) {
        return ResponseEntity.ok(ApiResponse.ok(toResponse(currentUser)));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse<UserResponse>> updateMe(
            @Valid @RequestBody UpdateUserRequest request,
            @AuthenticationPrincipal User currentUser) {

        User user = userRepository.findById(currentUser.getId())
                .orElseThrow(() -> new AppException(HttpStatus.NOT_FOUND,
                        "USER_NOT_FOUND", "User not found"));

        if (request.getFirstName() != null)     user.setFirstName(request.getFirstName());
        if (request.getLastName() != null)      user.setLastName(request.getLastName());
        if (request.getPhone() != null)         user.setPhone(request.getPhone());
        if (request.getProfileImageUrl() != null) user.setProfileImageUrl(request.getProfileImageUrl());

        userRepository.save(user);
        return ResponseEntity.ok(ApiResponse.ok(toResponse(user)));
    }

    /**
     * Returns a short-lived presigned S3 PUT URL for uploading a profile avatar.
     *
     * WHY presigned URL instead of accepting the image directly?
     * Uploading through the server wastes bandwidth and memory — the image goes
     * client → server → S3. A presigned URL lets the client upload directly to S3,
     * cutting the server out entirely. Same pattern used for listing photos.
     *
     * After the PUT succeeds, the client calls PUT /users/me with { profileImageUrl }
     * to persist the final URL.
     */
    @PostMapping("/me/avatar/presign")
    public ResponseEntity<ApiResponse<Map<String, String>>> presignAvatar(
            @AuthenticationPrincipal User currentUser) {
        String key = "avatars/" + currentUser.getId() + "/" + UUID.randomUUID() + ".jpg";
        String uploadUrl = s3Service.generatePresignedPutUrl(key);
        String imageUrl  = s3Service.getPublicUrl(key);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("uploadUrl", uploadUrl, "imageUrl", imageUrl)));
    }

    @PostMapping("/stripe-connect")
    @PreAuthorize("hasRole('HOST')")
    public ApiResponse<Map<String, String>> createConnectAccount(
            @AuthenticationPrincipal User currentUser) {
        String url = userService.createConnectOnboardingUrl(currentUser.getId());
        return ApiResponse.ok(Map.of("onboardingUrl", url));
    }

    @GetMapping("/stripe-connect/status")
    @PreAuthorize("hasRole('HOST')")
    public ApiResponse<ConnectStatusResponse> getConnectStatus(
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(userService.getConnectStatus(currentUser.getId()));
    }

    private UserResponse toResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .phone(user.getPhone())
                .profileImageUrl(user.getProfileImageUrl())
                .role(user.getRole())
                .build();
    }
}
