package com.kyrgyzexplore.listing.dto;

import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Getter
@NoArgsConstructor
public class UpdateListingRequest {

    @Size(max = 200, message = "Title must not exceed 200 characters")
    private String title;

    private String description;

    @DecimalMin(value = "0.01", message = "Price must be at least 0.01")
    private BigDecimal pricePerUnit;

    @Size(max = 3, message = "Currency code must be at most 3 characters")
    private String currency;

    @Min(value = 1, message = "Max guests must be at least 1")
    private Integer maxGuests;

    @DecimalMin(value = "-90.0", message = "Latitude must be between -90 and 90")
    @DecimalMax(value = "90.0", message = "Latitude must be between -90 and 90")
    private Double latitude;

    @DecimalMin(value = "-180.0", message = "Longitude must be between -180 and 180")
    @DecimalMax(value = "180.0", message = "Longitude must be between -180 and 180")
    private Double longitude;

    private String address;

    @Size(max = 100, message = "City must not exceed 100 characters")
    private String city;
}
