package com.kyrgyzexplore.booking;

import com.kyrgyzexplore.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "bookings")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Booking extends BaseEntity {

    @Column(nullable = false)
    private UUID listingId;

    @Column(nullable = false)
    private UUID travelerId;

    @Column(nullable = false)
    private LocalDate checkInDate;

    @Column(nullable = false)
    private LocalDate checkOutDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private BookingStatus status = BookingStatus.PENDING;

    @Column(nullable = false)
    private int numberOfGuests;

    // Locked at creation time — the listing price can change later, this must not
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal totalPrice;

    @Column(columnDefinition = "TEXT")
    private String guestMessage;

    @Column(columnDefinition = "TEXT")
    private String rejectionReason;

    private Instant confirmedAt;
    private Instant rejectedAt;
    private Instant cancelledAt;

    // Set at creation for PENDING bookings; null for all other statuses.
    private Instant expiresAt;

    @Column(length = 255)
    private String stripePaymentIntentId;  // set when traveler initiates payment

    private Instant paidAt;               // set by Stripe webhook on success
}
