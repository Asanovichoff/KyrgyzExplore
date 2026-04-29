package com.kyrgyzexplore.booking;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BookingRepository extends JpaRepository<Booking, UUID> {

    Page<Booking> findByTravelerIdOrderByCreatedAtDesc(UUID travelerId, Pageable pageable);

    @Query("""
        SELECT b FROM Booking b
        JOIN com.kyrgyzexplore.listing.Listing l ON l.id = b.listingId
        WHERE l.hostId = :hostId
        ORDER BY b.createdAt DESC
        """)
    Page<Booking> findByHostId(@Param("hostId") UUID hostId, Pageable pageable);

    /**
     * Returns true if any active booking for this listing overlaps the requested range.
     * CONFIRMED bookings always block. PENDING bookings only block if they haven't expired yet
     * (expiresAt > now). Expired PENDING bookings are treated as if they don't exist so their
     * dates are immediately available for new bookings — even before the cleanup job runs.
     * Two ranges [A,B) and [C,D) overlap when A < D AND C < B.
     */
    @Query("""
        SELECT COUNT(b) > 0 FROM Booking b
        WHERE b.listingId = :listingId
          AND (b.status = com.kyrgyzexplore.booking.BookingStatus.CONFIRMED
               OR (b.status = com.kyrgyzexplore.booking.BookingStatus.PENDING
                   AND b.expiresAt > :now))
          AND b.checkInDate  < :checkOut
          AND b.checkOutDate > :checkIn
        """)
    boolean existsConflict(
        @Param("listingId") UUID listingId,
        @Param("checkIn")   LocalDate checkIn,
        @Param("checkOut")  LocalDate checkOut,
        @Param("now")       Instant now
    );

    Optional<Booking> findByStripePaymentIntentId(String stripePaymentIntentId);

    /**
     * Returns all CONFIRMED or PAID bookings for a listing whose date range
     * overlaps [startDate, endDate). Used by AvailabilityService to compute
     * which days are blocked by existing bookings.
     *
     * WHY only CONFIRMED and PAID?
     * PENDING bookings have not been accepted by the host yet and expire after
     * 24 hours. Showing PENDING bookings as blocked on the availability calendar
     * would make dates look unavailable before the host has even accepted —
     * a confusing and misleading experience for travelers.
     */
    @Query("""
        SELECT b FROM Booking b
        WHERE b.listingId = :listingId
          AND b.status IN (
              com.kyrgyzexplore.booking.BookingStatus.CONFIRMED,
              com.kyrgyzexplore.booking.BookingStatus.PAID)
          AND b.checkInDate  < :endDate
          AND b.checkOutDate > :startDate
        """)
    List<Booking> findConfirmedOrPaidOverlapping(
        @Param("listingId")  UUID listingId,
        @Param("startDate")  LocalDate startDate,
        @Param("endDate")    LocalDate endDate
    );

    /**
     * Bulk-cancels all PENDING bookings whose expiry window has passed.
     * Called by BookingExpiryJob every 15 minutes.
     * Returns the number of rows updated for logging.
     */
    @Modifying
    @Query("""
        UPDATE Booking b
        SET b.status = com.kyrgyzexplore.booking.BookingStatus.CANCELLED,
            b.cancelledAt = :now
        WHERE b.status = com.kyrgyzexplore.booking.BookingStatus.PENDING
          AND b.expiresAt < :now
        """)
    int cancelExpiredBookings(@Param("now") Instant now);
}
