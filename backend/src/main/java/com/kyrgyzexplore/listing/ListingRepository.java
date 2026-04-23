package com.kyrgyzexplore.listing;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ListingRepository extends JpaRepository<Listing, UUID> {

    Page<Listing> findByHostIdAndDeletedAtIsNull(UUID hostId, Pageable pageable);

    Optional<Listing> findByIdAndDeletedAtIsNull(UUID id);
}
