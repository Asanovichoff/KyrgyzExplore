package com.kyrgyzexplore.review.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.Instant;
import java.util.UUID;

@Getter
@Builder
public class ReviewResponse {
    private UUID id;
    private UUID listingId;
    private UUID travelerId;
    private String travelerName;
    private UUID bookingId;
    private int rating;
    private String comment;
    private Instant createdAt;
}
