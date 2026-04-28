package com.kyrgyzexplore.auth;

import com.kyrgyzexplore.auth.dto.AuthResponse;
import com.kyrgyzexplore.auth.dto.LoginRequest;
import com.kyrgyzexplore.auth.dto.RegisterRequest;
import com.kyrgyzexplore.common.exception.AppException;
import com.kyrgyzexplore.email.EmailService;
import com.kyrgyzexplore.user.User;
import com.kyrgyzexplore.user.UserRepository;
import com.kyrgyzexplore.user.dto.UserResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        if (userRepository.existsByEmail(req.getEmail())) {
            throw new AppException(HttpStatus.CONFLICT, "EMAIL_TAKEN",
                    "An account with this email already exists");
        }

        User user = User.builder()
                .email(req.getEmail().toLowerCase())
                .passwordHash(passwordEncoder.encode(req.getPassword()))
                .role(req.getRole())
                .firstName(req.getFirstName())
                .lastName(req.getLastName())
                .build();

        userRepository.save(user);
        emailService.sendWelcome(user.getId());
        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest req) {
        User user = userRepository.findByEmail(req.getEmail().toLowerCase())
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        if (!user.isEnabled()) {
            throw new AppException(HttpStatus.FORBIDDEN, "ACCOUNT_SUSPENDED",
                    "Your account has been suspended");
        }

        if (!passwordEncoder.matches(req.getPassword(), user.getPasswordHash())) {
            // WHY throw BadCredentialsException here instead of AppException?
            // Spring Security's GlobalExceptionHandler already maps BadCredentialsException
            // to a 401. Also: always return the SAME error message for wrong email vs
            // wrong password — revealing which one is wrong helps attackers enumerate accounts.
            throw new BadCredentialsException("Invalid email or password");
        }

        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse refresh(String rawToken) {
        String hash = jwtService.hashToken(rawToken);

        RefreshToken stored = refreshTokenRepository.findByTokenHash(hash)
                .orElseThrow(() -> new AppException(HttpStatus.UNAUTHORIZED,
                        "INVALID_REFRESH_TOKEN", "Refresh token is invalid or expired"));

        if (!stored.isValid()) {
            // Token is expired or revoked — revoke ALL tokens for this user.
            // WHY revoke all? If an attacker got the old token and tries to refresh,
            // this protects the real user by forcing them to log in again.
            refreshTokenRepository.revokeAllForUser(stored.getUserId());
            throw new AppException(HttpStatus.UNAUTHORIZED,
                    "REFRESH_TOKEN_REUSE", "Session expired. Please log in again.");
        }

        User user = userRepository.findById(stored.getUserId())
                .orElseThrow(() -> new AppException(HttpStatus.UNAUTHORIZED,
                        "USER_NOT_FOUND", "User no longer exists"));

        // Revoke the used token (rotation: each refresh issues a brand new token)
        stored.setRevokedAt(Instant.now());
        refreshTokenRepository.save(stored);

        return buildAuthResponse(user);
    }

    @Transactional
    public void logout(String rawToken, UUID userId) {
        String hash = jwtService.hashToken(rawToken);
        refreshTokenRepository.findByTokenHash(hash)
                .ifPresent(t -> {
                    t.setRevokedAt(Instant.now());
                    refreshTokenRepository.save(t);
                });
        // We don't throw if token not found — logout should always succeed silently
    }

    private AuthResponse buildAuthResponse(User user) {
        String accessToken = jwtService.generateAccessToken(user);
        String rawRefreshToken = jwtService.generateRawRefreshToken();

        RefreshToken refreshToken = RefreshToken.builder()
                .userId(user.getId())
                .tokenHash(jwtService.hashToken(rawRefreshToken))
                .expiresAt(Instant.now().plusMillis(jwtService.getRefreshExpirationMs()))
                .build();
        refreshTokenRepository.save(refreshToken);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(rawRefreshToken)
                .user(toUserResponse(user))
                .build();
    }

    private UserResponse toUserResponse(User user) {
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
