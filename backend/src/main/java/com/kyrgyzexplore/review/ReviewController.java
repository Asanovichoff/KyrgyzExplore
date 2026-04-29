package com.kyrgyzexplore.review;

import com.kyrgyzexplore.common.dto.ApiResponse;
import com.kyrgyzexplore.review.dto.CreateReviewRequest;
import com.kyrgyzexplore.review.dto.ReviewResponse;
import com.kyrgyzexplore.user.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/reviews")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasRole('TRAVELER')")
    public ApiResponse<ReviewResponse> create(
            @Valid @RequestBody CreateReviewRequest request,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(reviewService.create(currentUser.getId(), request));
    }

    @GetMapping("/listing/{listingId}")
    public ApiResponse<Page<ReviewResponse>> getByListing(
            @PathVariable UUID listingId,
            @PageableDefault(size = 20) Pageable pageable) {
        return ApiResponse.ok(reviewService.getByListing(listingId, pageable));
    }

    @GetMapping("/my")
    public ApiResponse<Page<ReviewResponse>> getMyReviews(
            @AuthenticationPrincipal User currentUser,
            @PageableDefault(size = 20) Pageable pageable) {
        return ApiResponse.ok(reviewService.getByTraveler(currentUser.getId(), pageable));
    }

    @GetMapping("/host/{hostId}")
    public ApiResponse<Page<ReviewResponse>> getByHost(
            @PathVariable UUID hostId,
            @PageableDefault(size = 20) Pageable pageable) {
        return ApiResponse.ok(reviewService.getByHost(hostId, pageable));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('TRAVELER')")
    public ApiResponse<Void> delete(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser) {
        reviewService.delete(id, currentUser.getId());
        return ApiResponse.ok(null);
    }
}
