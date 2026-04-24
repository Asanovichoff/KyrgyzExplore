package com.kyrgyzexplore.listing;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ListingRepository extends JpaRepository<Listing, UUID> {

    Page<Listing> findByHostIdAndDeletedAtIsNull(UUID hostId, Pageable pageable);

    Optional<Listing> findByIdAndDeletedAtIsNull(UUID id);

    /**
     * Proximity search with optional filters.
     *
     * WHY ST_DWithin with ::geography cast?
     * The location column is geometry(Point,4326). Casting to geography makes
     * ST_DWithin accept the radius in meters (not degrees). PostGIS 3.x is smart
     * enough to still use the GiST geometry index internally when you cast.
     *
     * WHY <-> for ORDER BY instead of ST_Distance?
     * <-> is the PostGIS KNN (k-nearest-neighbour) operator. It does an index-driven
     * nearest-neighbour scan — very fast. ST_Distance would require computing the exact
     * distance for every row in the result set. Within the already-filtered radius the
     * sort order from <-> matches geographic order closely enough for a discovery screen.
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
            ORDER BY l.location <-> ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)
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
        Pageable pageable
    );
}
