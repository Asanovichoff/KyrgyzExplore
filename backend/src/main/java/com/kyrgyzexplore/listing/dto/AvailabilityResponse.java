package com.kyrgyzexplore.listing.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

@Getter
@AllArgsConstructor
public class AvailabilityResponse {

    /**
     * Sorted list of ISO-8601 date strings (YYYY-MM-DD) that are unavailable
     * for the requested month. Combines booking-derived blocks and host manual blocks.
     *
     * WHY strings instead of LocalDate?
     * Jackson serialises LocalDate as [year, month, day] array by default unless
     * a module is configured. Returning pre-formatted strings avoids that footgun
     * and gives the frontend exactly what it needs to render a calendar.
     */
    private final List<String> blockedDates;
}