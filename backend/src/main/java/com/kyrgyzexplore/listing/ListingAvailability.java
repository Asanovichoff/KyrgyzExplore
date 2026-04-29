package com.kyrgyzexplore.listing;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * WHY no BaseEntity?
 * These records are immutable after insert (no updatedAt) and intentionally simple.
 * We only need id, listing_id, date, and created_at.
 *
 * WHY not store booking-derived blocked dates here?
 * Bookings already have check-in/check-out dates in the bookings table.
 * Duplicating them here would create a sync problem — what happens when a booking
 * is cancelled? We'd have to delete rows from two tables atomically.
 * Instead, AvailabilityService computes booking blocks on-the-fly at query time,
 * and this table only stores host manual overrides (maintenance, personal use, etc.).
 */
@Entity
@Table(name = "listing_availability")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ListingAvailability {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(name = "listing_id", nullable = false)
    private UUID listingId;

    @Column(nullable = false)
    private LocalDate date;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false, nullable = false)
    private Instant createdAt;
}