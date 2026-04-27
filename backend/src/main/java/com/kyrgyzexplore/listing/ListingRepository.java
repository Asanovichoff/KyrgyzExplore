package com.kyrgyzexplore.listing;

import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ListingRepository extends JpaRepository<Listing, UUID> {

    Page<Listing> findByHostIdAndDeletedAtIsNull(UUID hostId, Pageable pageable);

    /**
     * Atomically recomputes averageRating and reviewCount for a listing from the
     * reviews table in a single SQL round-trip.
     *
     * WHY native query instead of JPQL?
     * JPQL UPDATE cannot reference another table in the SET clause. The native
     * subquery computes AVG + COUNT together so there's no gap between reading
     * the reviews and writing the listing — no race condition possible.
     *
     * WHY cast AVG to numeric(3,2)?
     * AVG(smallint) returns numeric with arbitrary precision in PostgreSQL.
     * Casting to numeric(3,2) matches the column definition on the listing
     * (precision=3, scale=2) and avoids a type mismatch error.
     *
     * When all reviews are deleted, the subquery returns NULL for avg_rating and
     * 0 for cnt, which correctly resets the listing stats.
     */
    @Modifying
    @Query(value = """
        UPDATE listings
        SET average_rating = sub.avg_rating,
            review_count   = sub.cnt,
            updated_at     = NOW()
        FROM (
            SELECT AVG(rating)::numeric(3,2) AS avg_rating,
                   COUNT(*)::int             AS cnt
            FROM reviews
            WHERE listing_id = :listingId
        ) sub
        WHERE id = :listingId
        """, nativeQuery = true)
    void recalculateRating(@Param("listingId") UUID listingId);

    Optional<Listing> findByIdAndDeletedAtIsNull(UUID id);

    /**
     * Used exclusively during booking creation. The PESSIMISTIC_WRITE lock issues
     * a SELECT ... FOR UPDATE, serialising concurrent booking attempts on the same
     * listing so the conflict check and the insert are atomic.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT l FROM Listing l WHERE l.id = :id AND l.deletedAt IS NULL")
    Optional<Listing> findByIdForBooking(@Param("id") UUID id);

    /**
     * Proximity search with optional filters.
     *
     * WHY ST_DWithin with ::geography cast?
     * The location column is geometry(Point,4326). Casting to geography makes
     * ST_DWithin accept the radius in meters (not degrees). PostGIS 3.x is smart
     * enough to still use the GiST geometry index internally when you cast.
     *
     * WHY <-> for ORDER BY instead of ST_Distance(::geography)?
     * <-> uses planar (Euclidean) distance in degrees; ST_Distance(::geography) uses
     * spherical distance in metres. For a discovery screen, <-> is fine because:
     *   - It uses the GiST index for a fast KNN scan (ST_Distance scans every filtered row)
     *   - At ≤100 km radius and ~42°N latitude the planar vs spherical ordering error is
     *     ≤1.4% — imperceptible to a traveller choosing between "2.3 km" and "2.4 km" away
     * The controller + service both enforce a 100 km cap to keep this error bounded.
     * If you ever need accurate sort beyond 100 km, replace <-> with
     * ST_Distance(l.location::geography, ST_SetSRID(ST_MakePoint(:lon,:lat),4326)::geography).
     *
     * WHY type as String not ListingType enum?
     * Native queries don't understand Java enums — they work with the raw VARCHAR value
     * stored in the DB. The service converts with type.name() before calling here.
     */
    @Query(
        value = """
            SELECT l.*
            FROM listings l
            WHERE l.deleted_at IS NULL
              AND l.is_active = TRUE
              AND ST_DWithin(
                    l.location::geography,
                    ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography,
                    :radiusMeters
                  )
              AND (:type IS NULL OR l.type = :type)
              AND (:minPrice IS NULL OR l.price_per_unit >= :minPrice)
              AND (:maxPrice IS NULL OR l.price_per_unit <= :maxPrice)
              AND (:city IS NULL OR LOWER(l.city) = LOWER(:city))
              AND (:minGuests IS NULL OR l.max_guests >= :minGuests)
              AND (
                    CAST(:checkIn AS date) IS NULL OR CAST(:checkOut AS date) IS NULL
                    OR NOT EXISTS (
                        SELECT 1 FROM bookings b
                        WHERE b.listing_id = l.id
                          AND b.status IN ('CONFIRMED', 'PAID')
                          AND b.check_in_date  < CAST(:checkOut AS date)
                          AND b.check_out_date > CAST(:checkIn AS date)
                    )
                  )
            ORDER BY
                CASE WHEN :sort = 'price_asc'  THEN l.price_per_unit ELSE NULL END ASC  NULLS LAST,
                CASE WHEN :sort = 'price_desc' THEN l.price_per_unit ELSE NULL END DESC NULLS LAST,
                CASE WHEN :sort = 'rating'     THEN l.average_rating ELSE NULL END DESC NULLS LAST,
                l.location <-> ST_SetSRID(ST_MakePoint(:lon, :lat), 4326) ASC
            """,
        countQuery = """
            SELECT COUNT(*)
            FROM listings l
            WHERE l.deleted_at IS NULL
              AND l.is_active = TRUE
              AND ST_DWithin(
                    l.location::geography,
                    ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography,
                    :radiusMeters
                  )
              AND (:type IS NULL OR l.type = :type)
              AND (:minPrice IS NULL OR l.price_per_unit >= :minPrice)
              AND (:maxPrice IS NULL OR l.price_per_unit <= :maxPrice)
              AND (:city IS NULL OR LOWER(l.city) = LOWER(:city))
              AND (:minGuests IS NULL OR l.max_guests >= :minGuests)
              AND (
                    CAST(:checkIn AS date) IS NULL OR CAST(:checkOut AS date) IS NULL
                    OR NOT EXISTS (
                        SELECT 1 FROM bookings b
                        WHERE b.listing_id = l.id
                          AND b.status IN ('CONFIRMED', 'PAID')
                          AND b.check_in_date  < CAST(:checkOut AS date)
                          AND b.check_out_date > CAST(:checkIn AS date)
                    )
                  )
            """,
        nativeQuery = true
    )
    Page<Listing> searchListings(
        @Param("lat") double lat,
        @Param("lon") double lon,
        @Param("radiusMeters") double radiusMeters,
        @Param("type") String type,
        @Param("minPrice") BigDecimal minPrice,
        @Param("maxPrice") BigDecimal maxPrice,
        @Param("city") String city,
        @Param("minGuests") Integer minGuests,
        @Param("checkIn") LocalDate checkIn,
        @Param("checkOut") LocalDate checkOut,
        @Param("sort") String sort,
        Pageable pageable
    );
}
