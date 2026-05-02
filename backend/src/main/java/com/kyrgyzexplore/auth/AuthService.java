package com.kyrgyzexplore.auth;

import com.kyrgyzexplore.auth.dto.AuthResponse;
import com.kyrgyzexplore.auth.dto.LoginRequest;
import com.kyrgyzexplore.auth.dto.RegisterRequest;
import com.kyrgyzexplore.common.exception.AppException;
import com.kyrgyzexplore.email.EmailService;
import com.kyrgyzexplore.user.User;
import com.kyrgyzexplore.user.UserRepository;
import com.kyrgyzexplore.user.UserRole;
import com.kyrgyzexplore.user.dto.UserResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.time.Instant;
import java.util.Map;
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

    /**
     * Authenticates a user via Google Sign-In.
     *
     * WHY call Google's tokeninfo endpoint instead of verifying the JWT locally?
     * Local JWT verification requires downloading and caching Google's public keys,
     * handling key rotation, and checking the `aud` claim matches our client ID.
     * For an MVP, delegating to Google's own endpoint is simpler and always up-to-date.
     * Swap to local verification if latency becomes a concern.
     *
     * WHY use a random placeholder passwordHash for social users?
     * The database column is NOT NULL. Social users never use a password, so we store
     * a random UUID that can never be guessed or matched by bcrypt — the account is
     * effectively password-less while satisfying the schema constraint.
     */
    @Transactional
    public AuthResponse loginWithGoogle(String idToken) {
        // Verify token with Google and extract user info
        // WHY RestTemplate here instead of WebClient?
        // This is a single synchronous call during login — no need for reactive overhead.
        // WHY not verify the JWT signature locally?
        // That requires fetching + caching Google's public keys and handling rotation.
        // Delegating to Google's own endpoint is simpler and always authoritative for MVP.
        RestTemplate rest = new RestTemplate();
        Map<?, ?> claims;
        try {
            claims = rest.getForObject(
                "https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken,
                Map.class
            );
        } catch (RestClientException e) {
            throw new AppException(HttpStatus.UNAUTHORIZED, "INVALID_GOOGLE_TOKEN",
                    "Google token verification failed");
        }

        if (claims == null || !claims.containsKey("email")) {
            throw new AppException(HttpStatus.UNAUTHORIZED, "INVALID_GOOGLE_TOKEN",
                    "Could not extract email from Google token");
        }

        String email     = String.valueOf(claims.get("email")).toLowerCase();
        String firstName = claims.containsKey("given_name")  ? String.valueOf(claims.get("given_name"))  : "";
        String lastName  = claims.containsKey("family_name") ? String.valueOf(claims.get("family_name")) : "";
        String picture   = claims.containsKey("picture")     ? String.valueOf(claims.get("picture"))     : null;

        User user = userRepository.findByEmail(email).orElseGet(() -> {
            User newUser = User.builder()
                    .email(email)
                    .passwordHash(UUID.randomUUID().toString()) // never used — social login only
                    .firstName(firstName.isEmpty() ? "User" : firstName)
                    .lastName(lastName)
                    .role(UserRole.TRAVELER)
                    .profileImageUrl(picture)
                    .build();
            return userRepository.save(newUser);
        });

        if (!user.isEnabled()) {
            throw new AppException(HttpStatus.FORBIDDEN, "ACCOUNT_SUSPENDED",
                    "Your account has been suspended");
        }

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
