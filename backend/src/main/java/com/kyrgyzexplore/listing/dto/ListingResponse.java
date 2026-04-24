package com.kyrgyzexplore.listing.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.kyrgyzexplore.listing.ListingType;
import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Getter
@Builder(toBuilder = true)
public class ListingResponse {
    private UUID id;
    private UUID hostId;
    private ListingType type;
    private String title;
    private String description;
    private BigDecimal pricePerUnit;
    private String currency;
    private Integer maxGuests;
    private Double latitude;
    private Double longitude;
    private String address;
    private String city;
    private String country;
    private BigDecimal averageRating;
    private int reviewCount;
    private boolean isActive;
    private List<ListingImageResponse> images;
    private Instant createdAt;
    private Instant updatedAt;

    // Only present in search results — null (and omitted from JSON) on single-listing fetches
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private Double distanceKm;
}
