package com.kyrgyzexplore.booking;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
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
     * Returns true if any PENDING or CONFIRMED booking for this listing overlaps
     * the requested date range. Two ranges [A,B) and [C,D) overlap when A < D AND C < B.
     * Uses the idx_bookings_availability partial index for performance.
     */
    @Query("""
        SELECT COUNT(b) > 0 FROM Booking b
        WHERE b.listingId = :listingId
          AND b.status IN (
                com.kyrgyzexplore.booking.BookingStatus.PENDING,
                com.kyrgyzexplore.booking.BookingStatus.CONFIRMED)
          AND b.checkInDate  < :checkOut
          AND b.checkOutDate > :checkIn
        """)
    boolean existsConflict(
        @Param("listingId") UUID listingId,
        @Param("checkIn")   LocalDate checkIn,
        @Param("checkOut")  LocalDate checkOut
    );
}
