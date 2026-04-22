package com.kyrgyzexplore.auth;

import com.kyrgyzexplore.user.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.Date;
import java.util.HexFormat;
import java.util.UUID;

/**
 * Generates and validates JWT access tokens, and hashes refresh tokens.
 *
 * HOW JWT WORKS (important to understand):
 * A JWT has 3 parts: header.payload.signature
 * - Header: algorithm used (HS256)
 * - Payload: the claims we store (userId, role, expiry)
 * - Signature: HMAC(header + payload, secret) — proves the token wasn't tampered with
 *
 * When we validate, we re-compute the signature from the header+payload and compare.
 * If they match, the token is authentic. If not, someone tampered with it.
 *
 * IMPORTANT: The payload is only BASE64 encoded, NOT encrypted.
 * Anyone can decode it. Never put sensitive data (passwords, PII) in JWT claims.
 */
@Slf4j
@Service
public class JwtService {

    private final SecretKey signingKey;
    private final long accessExpirationMs;
    private final long refreshExpirationMs;

    public JwtService(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.expiration-ms}") long accessExpirationMs,
            @Value("${jwt.refresh-expiration-ms}") long refreshExpirationMs) {
        // Key must be at least 32 bytes for HS256. Our dev secret is 36 chars — fine.
        this.signingKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessExpirationMs = accessExpirationMs;
        this.refreshExpirationMs = refreshExpirationMs;
    }

    /** Creates a signed JWT encoding the user's id and role. */
    public String generateAccessToken(User user) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(user.getId().toString())
                .claim("role", user.getRole().name())
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusMillis(accessExpirationMs)))
                .signWith(signingKey)
                .compact();
    }

    /** Returns a raw random token string. Store the SHA-256 hash of this, not the raw value. */
    public String generateRawRefreshToken() {
        return UUID.randomUUID().toString();
    }

    /** Returns how many ms until the refresh token expires (for setting expiresAt in DB). */
    public long getRefreshExpirationMs() {
        return refreshExpirationMs;
    }

    /** Extracts the userId claim from a validated token. */
    public UUID extractUserId(String token) {
        return UUID.fromString(parseClaims(token).getSubject());
    }

    /** Returns true if the token signature is valid and it hasn't expired. */
    public boolean isTokenValid(String token) {
        try {
            Claims claims = parseClaims(token);
            return !claims.getExpiration().before(new Date());
        } catch (JwtException | IllegalArgumentException e) {
            log.debug("Invalid JWT: {}", e.getMessage());
            return false;
        }
    }

    /**
     * Hashes a raw token with SHA-256.
     * We store this hash in the DB — never the raw token.
     * Even if an attacker reads the refresh_tokens table, they can't reverse a SHA-256 hash.
     */
    public String hashToken(String rawToken) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(rawToken.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(signingKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
