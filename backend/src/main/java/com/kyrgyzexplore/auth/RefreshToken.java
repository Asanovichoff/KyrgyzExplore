package com.kyrgyzexplore.auth;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * WHY doesn't RefreshToken extend BaseEntity?
 * BaseEntity provides updatedAt, but refresh tokens are never "updated" —
 * they are created once, then either expire or get a revokedAt timestamp.
 * An updatedAt column would be meaningless and would confuse Hibernate validation
 * since the DB table has no such column. Only use BaseEntity when the entity
 * truly needs both createdAt and updatedAt.
 */
@Entity
@Table(name = "refresh_tokens")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RefreshToken {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(nullable = false)
    private UUID userId;

    /**
     * We store SHA-256(rawToken), never the raw token.
     * If this table is ever leaked, attackers get useless hashes.
     * The client holds the raw token and sends it on refresh — we hash it and compare.
     */
    @Column(nullable = false, unique = true)
    private String tokenHash;

    @Column(nullable = false)
    private Instant expiresAt;

    private Instant revokedAt;

    @CreationTimestamp
    @Column(updatable = false, nullable = false)
    private Instant createdAt;

    public boolean isRevoked() {
        return revokedAt != null;
    }

    public boolean isExpired() {
        return Instant.now().isAfter(expiresAt);
    }

    public boolean isValid() {
        return !isRevoked() && !isExpired();
    }
}
