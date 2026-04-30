package com.kyrgyzexplore.booking.dto;

import com.kyrgyzexplore.booking.BookingStatus;
import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Getter
@Builder
public class BookingResponse {
    private UUID id;
    private UUID listingId;
    private String listingTitle;
    private UUID travelerId;
    private BookingStatus status;
    private LocalDate checkInDate;
    private LocalDate checkOutDate;
    private int numberOfGuests;
    private long nightCount;
    private BigDecimal totalPrice;
    private String guestMessage;
    private String rejectionReason;
    private Instant confirmedAt;
    private Instant rejectedAt;
    private Instant cancelledAt;
    private Instant expiresAt;
    private String stripePaymentIntentId;
    private Instant paidAt;
    private Instant createdAt;
    private Instant updatedAt;
}
