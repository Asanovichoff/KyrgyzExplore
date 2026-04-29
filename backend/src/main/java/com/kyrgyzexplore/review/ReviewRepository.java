package com.kyrgyzexplore.review;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ReviewRepository extends JpaRepository<Review, UUID> {

    Page<Review> findByListingIdOrderByCreatedAtDesc(UUID listingId, Pageable pageable);

    Page<Review> findByTravelerIdOrderByCreatedAtDesc(UUID travelerId, Pageable pageable);

    boolean existsByBookingId(UUID bookingId);

    @Query("""
        SELECT r FROM Review r
        JOIN com.kyrgyzexplore.listing.Listing l ON l.id = r.listingId
        WHERE l.hostId = :hostId
        ORDER BY r.createdAt DESC
        """)
    Page<Review> findByHostId(@Param("hostId") UUID hostId, Pageable pageable);
}
