package com.kyrgyzexplore.listing.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.Collections;
import java.util.List;

@Getter
@NoArgsConstructor
public class UpdateAvailabilityRequest {

    /**
     * Dates the host wants to manually block (e.g. maintenance, personal use).
     * Already-blocked dates are ignored (idempotent).
     */
    private List<LocalDate> blockedDates = Collections.emptyList();

    /**
     * Dates the host wants to unblock. Only removes manual blocks —
     * dates blocked by a confirmed booking cannot be unblocked here.
     * Dates that are not manually blocked are ignored (idempotent).
     */
    private List<LocalDate> unblockedDates = Collections.emptyList();
}