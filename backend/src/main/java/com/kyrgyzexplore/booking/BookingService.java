package com.kyrgyzexplore.booking;

import com.kyrgyzexplore.booking.dto.BookingResponse;
import com.kyrgyzexplore.booking.dto.CreateBookingRequest;
import com.kyrgyzexplore.common.exception.AppException;
import com.kyrgyzexplore.listing.Listing;
import com.kyrgyzexplore.listing.ListingRepository;
import com.kyrgyzexplore.notification.NotificationService;
import com.kyrgyzexplore.notification.NotificationType;
import com.kyrgyzexplore.payment.PaymentService;
import com.kyrgyzexplore.payment.dto.PaymentIntentResponse;
import com.kyrgyzexplore.config.StripeConfig;
import com.stripe.model.PaymentIntent;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class BookingService {

    private final BookingRepository bookingRepository;
    private final ListingRepository listingRepository;
    private final PaymentService paymentService;
    private final StripeConfig stripeConfig;
    private final NotificationService notificationService;

    @Transactional
    public BookingResponse create(UUID travelerId, CreateBookingRequest req) {
        // Pessimistic lock — serialises concurrent booking attempts for the same listing
        Listing listing = listingRepository.findByIdForBooking(req.getListingId())
                .orElseThrow(() -> AppException.notFound("LISTING_NOT_FOUND", "Listing not found"));

        if (!listing.isActive() || listing.isDeleted()) {
            throw AppException.badRequest("LISTING_UNAVAILABLE", "This listing is not available for booking");
        }

        if (listing.getHostId().equals(travelerId)) {
            throw AppException.forbidden("SELF_BOOKING", "You cannot book your own listing");
        }

        if (!req.getCheckInDate().isBefore(req.getCheckOutDate())) {
            throw AppException.badRequest("INVALID_DATES", "Check-out date must be after check-in date");
        }

        if (listing.getMaxGuests() != null && req.getNumberOfGuests() > listing.getMaxGuests()) {
            throw AppException.badRequest("TOO_MANY_GUESTS",
                    "This listing accommodates at most " + listing.getMaxGuests() + " guests");
        }

        if (bookingRepository.existsConflict(req.getListingId(), req.getCheckInDate(), req.getCheckOutDate(), Instant.now())) {
            throw AppException.badRequest("BOOKING_CONFLICT", "These dates are already booked");
        }

        long nights = ChronoUnit.DAYS.between(req.getCheckInDate(), req.getCheckOutDate());
        BigDecimal totalPrice = listing.getPricePerUnit().multiply(BigDecimal.valueOf(nights));

        Booking booking = Booking.builder()
                .listingId(req.getListingId())
                .travelerId(travelerId)
                .checkInDate(req.getCheckInDate())
                .checkOutDate(req.getCheckOutDate())
                .numberOfGuests(req.getNumberOfGuests())
                .totalPrice(totalPrice)
                .guestMessage(req.getGuestMessage())
                .expiresAt(Instant.now().plus(24, ChronoUnit.HOURS))
                .build();

        return toResponse(bookingRepository.save(booking));
    }

    @Transactional
    public BookingResponse confirm(UUID bookingId, UUID hostId) {
        Booking booking = loadAndVerifyHost(bookingId, hostId);
        assertStatus(booking, BookingStatus.PENDING, "Only PENDING bookings can be confirmed");

        booking.setStatus(BookingStatus.CONFIRMED);
        booking.setConfirmedAt(Instant.now());
        BookingResponse response = toResponse(bookingRepository.save(booking));

        notificationService.notify(booking.getTravelerId(), NotificationType.BOOKING_CONFIRMED,
                "Booking confirmed", "Your booking has been confirmed by the host.", bookingId);

        return response;
    }

    @Transactional
    public BookingResponse reject(UUID bookingId, UUID hostId, String reason) {
        Booking booking = loadAndVerifyHost(bookingId, hostId);
        assertStatus(booking, BookingStatus.PENDING, "Only PENDING bookings can be rejected");

        booking.setStatus(BookingStatus.REJECTED);
        booking.setRejectedAt(Instant.now());
        booking.setRejectionReason(reason);
        BookingResponse response = toResponse(bookingRepository.save(booking));

        notificationService.notify(booking.getTravelerId(), NotificationType.BOOKING_REJECTED,
                "Booking declined", "Unfortunately your booking request was declined.", bookingId);

        return response;
    }

    @Transactional
    public BookingResponse cancel(UUID bookingId, UUID callerId) {
        Booking booking = loadBookingOrThrow(bookingId);
        verifyTravelerOrHost(booking, callerId);

        if (booking.getStatus() == BookingStatus.REJECTED || booking.getStatus() == BookingStatus.CANCELLED) {
            throw AppException.badRequest("INVALID_STATUS",
                    "Cannot cancel a booking that is already " + booking.getStatus().name().toLowerCase());
        }

        booking.setStatus(BookingStatus.CANCELLED);
        booking.setCancelledAt(Instant.now());
        BookingResponse response = toResponse(bookingRepository.save(booking));

        // Notify the party who did NOT cancel
        Listing listing = listingRepository.findByIdAndDeletedAtIsNull(booking.getListingId())
                .orElse(null);
        if (listing != null) {
            boolean callerIsTraveler = booking.getTravelerId().equals(callerId);
            UUID otherParty = callerIsTraveler ? listing.getHostId() : booking.getTravelerId();
            String msg = callerIsTraveler
                    ? "The traveler has cancelled their booking."
                    : "The host has cancelled your booking.";
            notificationService.notify(otherParty, NotificationType.BOOKING_CANCELLED,
                    "Booking cancelled", msg, bookingId);
        }

        return response;
    }

    @Transactional(readOnly = true)
    public BookingResponse getById(UUID bookingId, UUID callerId) {
        Booking booking = loadBookingOrThrow(bookingId);
        verifyTravelerOrHost(booking, callerId);
        return toResponse(booking);
    }

    @Transactional(readOnly = true)
    public Page<BookingResponse> getMyBookings(UUID travelerId, Pageable pageable) {
        return bookingRepository.findByTravelerIdOrderByCreatedAtDesc(travelerId, pageable)
                .map(this::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<BookingResponse> getHostBookings(UUID hostId, Pageable pageable) {
        return bookingRepository.findByHostId(hostId, pageable)
                .map(this::toResponse);
    }

    @Transactional
    public PaymentIntentResponse initiatePayment(UUID bookingId, UUID travelerId) {
        Booking booking = loadBookingOrThrow(bookingId);

        if (!booking.getTravelerId().equals(travelerId)) {
            throw AppException.forbidden("BOOKING_FORBIDDEN", "Only the traveler can pay for this booking");
        }
        assertStatus(booking, BookingStatus.CONFIRMED, "Only CONFIRMED bookings can be paid");

        // Idempotent — if a PaymentIntent was already created (e.g. traveler hit pay twice),
        // retrieve the existing one rather than creating a duplicate charge.
        if (booking.getStripePaymentIntentId() != null) {
            try {
                PaymentIntent existing = PaymentIntent.retrieve(booking.getStripePaymentIntentId());
                return new PaymentIntentResponse(existing.getClientSecret(),
                        stripeConfig.getPublishableKey(), booking.getTotalPrice());
            } catch (com.stripe.exception.StripeException e) {
                throw AppException.internalServerError("STRIPE_ERROR", "Could not retrieve existing payment");
            }
        }

        PaymentIntent intent = paymentService.createPaymentIntent(booking.getTotalPrice(), bookingId);
        booking.setStripePaymentIntentId(intent.getId());
        bookingRepository.save(booking);

        return new PaymentIntentResponse(intent.getClientSecret(),
                stripeConfig.getPublishableKey(), booking.getTotalPrice());
    }

    @Transactional
    public void markPaid(String paymentIntentId) {
        Booking booking = bookingRepository.findByStripePaymentIntentId(paymentIntentId)
                .orElseThrow(() -> AppException.notFound("BOOKING_NOT_FOUND",
                        "No booking found for payment intent " + paymentIntentId));

        booking.setStatus(BookingStatus.PAID);
        booking.setPaidAt(Instant.now());
        bookingRepository.save(booking);

        notificationService.notify(booking.getTravelerId(), NotificationType.BOOKING_PAID,
                "Payment received", "Your payment was successful. Enjoy your trip!", booking.getId());

        listingRepository.findByIdAndDeletedAtIsNull(booking.getListingId()).ifPresent(listing ->
            notificationService.notify(listing.getHostId(), NotificationType.BOOKING_PAID,
                    "Payment received", "A traveler has completed payment for their booking.", booking.getId())
        );
    }

    // ---- private helpers ----

    private Booking loadBookingOrThrow(UUID id) {
        return bookingRepository.findById(id)
                .orElseThrow(() -> AppException.notFound("BOOKING_NOT_FOUND", "Booking not found"));
    }

    private Booking loadAndVerifyHost(UUID bookingId, UUID hostId) {
        Booking booking = loadBookingOrThrow(bookingId);
        Listing listing = listingRepository.findByIdAndDeletedAtIsNull(booking.getListingId())
                .orElseThrow(() -> AppException.notFound("LISTING_NOT_FOUND", "Listing not found"));
        if (!listing.getHostId().equals(hostId)) {
            throw AppException.forbidden("BOOKING_FORBIDDEN", "You do not own the listing for this booking");
        }
        return booking;
    }

    private void verifyTravelerOrHost(Booking booking, UUID callerId) {
        if (booking.getTravelerId().equals(callerId)) return;

        // Check if caller is the host of the listing
        listingRepository.findByIdAndDeletedAtIsNull(booking.getListingId())
                .filter(l -> l.getHostId().equals(callerId))
                .orElseThrow(() -> AppException.forbidden("BOOKING_FORBIDDEN",
                        "Only the traveler or the listing host can perform this action"));
    }

    private static void assertStatus(Booking booking, BookingStatus required, String message) {
        if (booking.getStatus() != required) {
            throw AppException.badRequest("INVALID_STATUS", message);
        }
    }

    private BookingResponse toResponse(Booking b) {
        return BookingResponse.builder()
                .id(b.getId())
                .listingId(b.getListingId())
                .travelerId(b.getTravelerId())
                .status(b.getStatus())
                .checkInDate(b.getCheckInDate())
                .checkOutDate(b.getCheckOutDate())
                .numberOfGuests(b.getNumberOfGuests())
                .nightCount(ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate()))
                .totalPrice(b.getTotalPrice())
                .guestMessage(b.getGuestMessage())
                .rejectionReason(b.getRejectionReason())
                .confirmedAt(b.getConfirmedAt())
                .rejectedAt(b.getRejectedAt())
                .cancelledAt(b.getCancelledAt())
                .expiresAt(b.getExpiresAt())
                .stripePaymentIntentId(b.getStripePaymentIntentId())
                .paidAt(b.getPaidAt())
                .createdAt(b.getCreatedAt())
                .updatedAt(b.getUpdatedAt())
                .build();
    }
}
