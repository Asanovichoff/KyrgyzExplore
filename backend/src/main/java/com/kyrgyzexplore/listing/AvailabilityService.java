package com.kyrgyzexplore.listing;

import com.kyrgyzexplore.booking.Booking;
import com.kyrgyzexplore.booking.BookingRepository;
import com.kyrgyzexplore.common.exception.AppException;
import com.kyrgyzexplore.listing.dto.AvailabilityResponse;
import com.kyrgyzexplore.listing.dto.UpdateAvailabilityRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AvailabilityService {

    private final ListingRepository listingRepository;
    private final ListingAvailabilityRepository availabilityRepository;
    private final BookingRepository bookingRepository;

    /**
     * Returns all blocked dates for a listing in the given year/month.
     *
     * Blocked dates come from two sources:
     *   1. Confirmed/paid bookings — computed on-the-fly from the bookings table.
     *      WHY on-the-fly and not stored? Bookings can be cancelled, so caching
     *      them in a separate table would require keeping two tables in sync.
     *      Computing from the authoritative source is simpler and always correct.
     *   2. Manual host blocks — stored in listing_availability.
     *
     * WHY expand bookings into individual dates?
     * The frontend calendar needs a flat list of blocked days to colour individual
     * cells. A range like [checkIn, checkOut) would require the client to expand it.
     * Doing it server-side is simpler and keeps the API contract clean.
     *
     * WHY checkOut is exclusive (not included)?
     * Check-out day guests are leaving — the listing is available for the next guest
     * to check in on that same day (back-to-back bookings). This matches Airbnb's
     * convention.
     */
    @Transactional(readOnly = true)
    public AvailabilityResponse getBlockedDates(UUID listingId, int year, int month) {
        listingRepository.findByIdAndDeletedAtIsNull(listingId)
                .orElseThrow(() -> AppException.notFound("LISTING_NOT_FOUND", "Listing not found"));

        LocalDate monthStart = LocalDate.of(year, month, 1);
        LocalDate monthEnd   = monthStart.plusMonths(1); // exclusive

        Set<LocalDate> blocked = new HashSet<>();

        // 1. Expand confirmed/paid bookings into individual dates
        List<Booking> bookings = bookingRepository
                .findConfirmedOrPaidOverlapping(listingId, monthStart, monthEnd);

        for (Booking b : bookings) {
            // Clamp to the requested month so we don't return dates outside it
            LocalDate from = b.getCheckInDate().isBefore(monthStart) ? monthStart : b.getCheckInDate();
            LocalDate to   = b.getCheckOutDate().isAfter(monthEnd)   ? monthEnd   : b.getCheckOutDate();
            // Iterate [from, to) — to is exclusive (check-out day is free)
            for (LocalDate d = from; d.isBefore(to); d = d.plusDays(1)) {
                blocked.add(d);
            }
        }

        // 2. Add manual host blocks
        blocked.addAll(
            availabilityRepository.findDatesByListingIdAndDateBetween(listingId, monthStart, monthEnd)
        );

        List<String> sorted = blocked.stream()
                .sorted()
                .map(LocalDate::toString)
                .toList();

        return new AvailabilityResponse(sorted);
    }

    /**
     * Adds or removes manual host blocks for a listing.
     * Returns the total number of dates actually changed (skips no-ops).
     *
     * WHY can't hosts unblock booking-derived dates?
     * A confirmed booking is a contract between host and traveler.
     * Allowing the host to unblock those dates via the availability API
     * would silently make dates look available while a booking still exists.
     * To cancel a booking, the host must use the cancellation endpoint.
     */
    @Transactional
    public int updateAvailability(UUID listingId, UUID hostId, UpdateAvailabilityRequest req) {
        Listing listing = listingRepository.findByIdAndDeletedAtIsNull(listingId)
                .orElseThrow(() -> AppException.notFound("LISTING_NOT_FOUND", "Listing not found"));

        if (!listing.getHostId().equals(hostId)) {
            throw AppException.forbidden("LISTING_FORBIDDEN", "You do not own this listing");
        }

        int changed = 0;

        for (LocalDate date : req.getBlockedDates()) {
            if (!availabilityRepository.existsByListingIdAndDate(listingId, date)) {
                availabilityRepository.save(
                        ListingAvailability.builder()
                                .listingId(listingId)
                                .date(date)
                                .build()
                );
                changed++;
            }
        }

        for (LocalDate date : req.getUnblockedDates()) {
            changed += availabilityRepository.deleteByListingIdAndDate(listingId, date);
        }

        return changed;
    }
}