package com.kyrgyzexplore.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.kyrgyzexplore.auth.dto.AuthResponse;
import com.kyrgyzexplore.auth.dto.LoginRequest;
import com.kyrgyzexplore.auth.dto.RegisterRequest;
import com.kyrgyzexplore.common.exception.AppException;
import com.kyrgyzexplore.email.EmailService;
import com.kyrgyzexplore.user.User;
import com.kyrgyzexplore.user.UserRepository;
import com.kyrgyzexplore.user.UserRole;
import com.kyrgyzexplore.user.dto.UserResponse;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.math.BigInteger;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.PublicKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.RSAPublicKeySpec;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
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
    private final ObjectMapper objectMapper;

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

    /**
     * Authenticates a user via Apple Sign-In.
     *
     * WHY verify Apple tokens with JWKS instead of Apple's tokeninfo endpoint?
     * Apple does not provide a simple tokeninfo HTTP call like Google. Apple
     * identity tokens are signed JWTs — we must fetch Apple's public keys (JWKS),
     * find the key matching the token's `kid` header, reconstruct the RSA public key
     * from its modulus (n) and exponent (e), then verify the signature with JJWT.
     *
     * WHY parse the JWT header manually before calling JJWT?
     * JJWT needs the public key up front (unlike asymmetric server-side verification
     * where the key is implicit). We peek at the `kid` claim in the header first so
     * we can select the right Apple key before handing the full token to JJWT.
     */
    @Transactional
    public AuthResponse loginWithApple(String identityToken) {
        // 1. Peek at the JWT header to get the key ID (kid)
        String[] parts = identityToken.split("\\.");
        if (parts.length != 3) {
            throw new AppException(HttpStatus.UNAUTHORIZED, "INVALID_APPLE_TOKEN", "Malformed Apple token");
        }
        Map<?, ?> header;
        try {
            String headerJson = new String(Base64.getUrlDecoder().decode(parts[0]));
            header = objectMapper.readValue(headerJson, Map.class);
        } catch (Exception e) {
            throw new AppException(HttpStatus.UNAUTHORIZED, "INVALID_APPLE_TOKEN", "Could not decode Apple token header");
        }
        String kid = String.valueOf(header.get("kid"));

        // 2. Fetch Apple's JWKS (public signing keys)
        RestTemplate rest = new RestTemplate();
        Map<?, ?> jwks;
        try {
            jwks = rest.getForObject("https://appleid.apple.com/auth/keys", Map.class);
        } catch (RestClientException e) {
            throw new AppException(HttpStatus.UNAUTHORIZED, "INVALID_APPLE_TOKEN", "Could not fetch Apple public keys");
        }
        if (jwks == null) {
            throw new AppException(HttpStatus.UNAUTHORIZED, "INVALID_APPLE_TOKEN", "Empty JWKS response from Apple");
        }

        // 3. Find the key whose kid matches the token header
        List<?> keys = (List<?>) jwks.get("keys");
        @SuppressWarnings("unchecked")
        Map<String, Object> matchedKey = (Map<String, Object>) keys.stream()
                .filter(k -> kid.equals(((Map<?, ?>) k).get("kid")))
                .findFirst()
                .orElseThrow(() -> new AppException(HttpStatus.UNAUTHORIZED,
                        "INVALID_APPLE_TOKEN", "No matching Apple key found for kid: " + kid));

        // 4. Reconstruct RSA public key from the JWKS modulus (n) and exponent (e).
        //    Both are Base64url-encoded big-endian byte arrays per the JWKS spec (RFC 7517).
        PublicKey publicKey;
        try {
            BigInteger modulus  = new BigInteger(1, Base64.getUrlDecoder().decode((String) matchedKey.get("n")));
            BigInteger exponent = new BigInteger(1, Base64.getUrlDecoder().decode((String) matchedKey.get("e")));
            publicKey = KeyFactory.getInstance("RSA").generatePublic(new RSAPublicKeySpec(modulus, exponent));
        } catch (NoSuchAlgorithmException | InvalidKeySpecException e) {
            throw new AppException(HttpStatus.INTERNAL_SERVER_ERROR, "KEY_BUILD_FAILED", "Could not build Apple public key");
        }

        // 5. Verify the token signature and parse claims with JJWT
        Claims claims;
        try {
            claims = Jwts.parser()
                    .verifyWith((java.security.PublicKey) publicKey)
                    .build()
                    .parseSignedClaims(identityToken)
                    .getPayload();
        } catch (JwtException e) {
            throw new AppException(HttpStatus.UNAUTHORIZED, "INVALID_APPLE_TOKEN", "Apple token verification failed");
        }

        String email = claims.get("email", String.class);
        if (email == null) {
            throw new AppException(HttpStatus.UNAUTHORIZED, "INVALID_APPLE_TOKEN",
                    "No email in Apple token — user may have hidden their email");
        }

        User user = userRepository.findByEmail(email.toLowerCase()).orElseGet(() -> {
            // Apple only provides the user's name on the very first sign-in.
            // We store a placeholder; the user can update it via their profile.
            User newUser = User.builder()
                    .email(email.toLowerCase())
                    .passwordHash(UUID.randomUUID().toString()) // never used — social login only
                    .firstName("Apple")
                    .lastName("User")
                    .role(UserRole.TRAVELER)
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
