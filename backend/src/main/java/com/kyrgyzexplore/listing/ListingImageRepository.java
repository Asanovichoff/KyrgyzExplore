package com.kyrgyzexplore.listing;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ListingImageRepository extends JpaRepository<ListingImage, UUID> {

    Optional<ListingImage> findByIdAndListing_Id(UUID id, UUID listingId);
}
