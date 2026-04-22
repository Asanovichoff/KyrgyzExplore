package com.kyrgyzexplore.auth;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {

    Optional<RefreshToken> findByTokenHash(String tokenHash);

    /**
     * Revokes all active tokens for a user (used on logout or security reset).
     * WHY @Modifying + @Query?
     * Spring Data JPA can't express "update multiple rows" with a method name alone.
     * @Modifying tells Spring this query writes data (not just reads it),
     * so it flushes the EntityManager and triggers a real UPDATE statement.
     */
    @Modifying
    @Query("UPDATE RefreshToken r SET r.revokedAt = CURRENT_TIMESTAMP WHERE r.userId = :userId AND r.revokedAt IS NULL")
    void revokeAllForUser(UUID userId);
}
