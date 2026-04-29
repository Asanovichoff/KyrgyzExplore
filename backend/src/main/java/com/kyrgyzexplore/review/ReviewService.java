package com.kyrgyzexplore.review;

import com.kyrgyzexplore.booking.Booking;
import com.kyrgyzexplore.booking.BookingRepository;
import com.kyrgyzexplore.booking.BookingStatus;
import com.kyrgyzexplore.common.exception.AppException;
import com.kyrgyzexplore.listing.ListingRepository;
import com.kyrgyzexplore.review.dto.CreateReviewRequest;
import com.kyrgyzexplore.review.dto.ReviewResponse;
import com.kyrgyzexplore.user.User;
import com.kyrgyzexplore.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final BookingRepository bookingRepository;
    private final ListingRepository listingRepository;
    private final UserRepository userRepository;

    @Transactional
    public ReviewResponse create(UUID travelerId, CreateReviewRequest req) {
        Booking booking = bookingRepository.findById(req.getBookingId())
                .orElseThrow(() -> AppException.notFound("BOOKING_NOT_FOUND", "Booking not found"));

        if (!booking.getTravelerId().equals(travelerId)) {
            throw AppException.forbidden("REVIEW_FORBIDDEN", "You can only review your own bookings");
        }

        if (booking.getStatus() != BookingStatus.PAID) {
            throw AppException.badRequest("BOOKING_NOT_ELIGIBLE",
                    "You can only review a booking after payment is complete");
        }

        if (reviewRepository.existsByBookingId(req.getBookingId())) {
            throw AppException.badRequest("ALREADY_REVIEWED", "You have already reviewed this booking");
        }

        Review review = Review.builder()
                .listingId(booking.getListingId())
                .travelerId(travelerId)
                .bookingId(req.getBookingId())
                .rating(req.getRating())
                .comment(req.getComment())
                .build();

        Review saved = reviewRepository.save(review);
        listingRepository.recalculateRating(booking.getListingId());

        User traveler = userRepository.findById(travelerId)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "User not found"));

        return toResponse(saved, traveler);
    }

    @Transactional
    public void delete(UUID reviewId, UUID travelerId) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> AppException.notFound("REVIEW_NOT_FOUND", "Review not found"));

        if (!review.getTravelerId().equals(travelerId)) {
            throw AppException.forbidden("REVIEW_FORBIDDEN", "You can only delete your own reviews");
        }

        UUID listingId = review.getListingId();
        reviewRepository.delete(review);
        listingRepository.recalculateRating(listingId);
    }

    @Transactional(readOnly = true)
    public Page<ReviewResponse> getByListing(UUID listingId, Pageable pageable) {
        return reviewRepository.findByListingIdOrderByCreatedAtDesc(listingId, pageable)
                .map(r -> {
                    User traveler = userRepository.findById(r.getTravelerId())
                            .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "User not found"));
                    return toResponse(r, traveler);
                });
    }

    @Transactional(readOnly = true)
    public Page<ReviewResponse> getByTraveler(UUID travelerId, Pageable pageable) {
        return reviewRepository.findByTravelerIdOrderByCreatedAtDesc(travelerId, pageable)
                .map(r -> {
                    User traveler = userRepository.findById(r.getTravelerId())
                            .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "User not found"));
                    return toResponse(r, traveler);
                });
    }

    @Transactional(readOnly = true)
    public Page<ReviewResponse> getByHost(UUID hostId, Pageable pageable) {
        return reviewRepository.findByHostId(hostId, pageable)
                .map(r -> {
                    User traveler = userRepository.findById(r.getTravelerId())
                            .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "User not found"));
                    return toResponse(r, traveler);
                });
    }

    private ReviewResponse toResponse(Review r, User traveler) {
        return ReviewResponse.builder()
                .id(r.getId())
                .listingId(r.getListingId())
                .travelerId(r.getTravelerId())
                .travelerName(traveler.getFirstName() + " " + traveler.getLastName())
                .bookingId(r.getBookingId())
                .rating(r.getRating())
                .comment(r.getComment())
                .createdAt(r.getCreatedAt())
                .build();
    }
}
