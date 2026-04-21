package com.kyrgyzexplore.common.entity;

import jakarta.persistence.*;
import lombok.Getter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * All JPA entities extend this. Provides id, createdAt, updatedAt automatically.
 *
 * WHY UUID instead of Long id?
 * UUIDs don't reveal row counts, can be generated client-side, and are safe to expose in URLs.
 * The trade-off is slightly larger storage and slower index lookups vs. sequential integers.
 * For this app size, UUIDs are the right call.
 *
 * WHY @MappedSuperclass instead of @Entity?
 * @MappedSuperclass means this class has no table of its own — its fields get merged into
 * each child table. That gives us one id column per table (correct), not a shared parent table.
 */
@MappedSuperclass
@Getter
public abstract class BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @CreationTimestamp
    @Column(updatable = false, nullable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private Instant updatedAt;
}
