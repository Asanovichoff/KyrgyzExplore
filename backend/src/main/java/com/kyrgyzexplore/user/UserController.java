package com.kyrgyzexplore.user;

import com.kyrgyzexplore.common.dto.ApiResponse;
import com.kyrgyzexplore.common.exception.AppException;
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

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;
    private final UserService userService;

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

        if (request.getFirstName() != null) user.setFirstName(request.getFirstName());
        if (request.getLastName() != null) user.setLastName(request.getLastName());
        if (request.getPhone() != null) user.setPhone(request.getPhone());

        userRepository.save(user);
        return ResponseEntity.ok(ApiResponse.ok(toResponse(user)));
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
