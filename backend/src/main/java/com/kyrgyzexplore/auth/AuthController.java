package com.kyrgyzexplore.auth;

import com.kyrgyzexplore.auth.dto.AuthResponse;
import com.kyrgyzexplore.auth.dto.LoginRequest;
import com.kyrgyzexplore.auth.dto.RefreshRequest;
import com.kyrgyzexplore.auth.dto.RegisterRequest;
import com.kyrgyzexplore.common.dto.ApiResponse;
import com.kyrgyzexplore.user.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(
            @Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(authService.register(request)));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(authService.login(request)));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(
            @Valid @RequestBody RefreshRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(authService.refresh(request.getRefreshToken())));
    }

    /**
     * @AuthenticationPrincipal injects the currently authenticated User from the
     * SecurityContext — set by JwtAuthFilter. No DB lookup needed here.
     */
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(
            @Valid @RequestBody RefreshRequest request,
            @AuthenticationPrincipal User currentUser) {
        authService.logout(request.getRefreshToken(), currentUser.getId());
        return ResponseEntity.ok(ApiResponse.ok(null, "Logged out successfully"));
    }
}
