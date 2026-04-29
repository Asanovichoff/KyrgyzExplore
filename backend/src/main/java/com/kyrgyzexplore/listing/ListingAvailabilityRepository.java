package com.kyrgyzexplore.listing;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface ListingAvailabilityRepository extends JpaRepository<ListingAvailability, UUID> {

    /**
     * Returns all manually blocked dates for a listing within the given range (inclusive).
     * Used by AvailabilityService to merge with booking-derived blocked dates.
     */
    @Query("SELECT a.date FROM ListingAvailability a " +
           "WHERE a.listingId = :listingId " +
           "AND a.date >= :startDate AND a.date < :endDate")
    List<LocalDate> findDatesByListingIdAndDateBetween(
            @Param("listingId") UUID listingId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate")   LocalDate endDate
    );

    boolean existsByListingIdAndDate(UUID listingId, LocalDate date);

    /**
     * Returns the number of deleted rows — used by AvailabilityService
     * to count how many dates were actually unblocked.
     */
    @Modifying
    @Query("DELETE FROM ListingAvailability a " +
           "WHERE a.listingId = :listingId AND a.date = :date")
    int deleteByListingIdAndDate(
            @Param("listingId") UUID listingId,
            @Param("date")      LocalDate date
    );
}