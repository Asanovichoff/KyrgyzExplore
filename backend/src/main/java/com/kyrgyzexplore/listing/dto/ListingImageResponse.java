package com.kyrgyzexplore.listing.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.UUID;

@Getter
@AllArgsConstructor
public class ListingImageResponse {
    private UUID id;
    private String url;
    private short displayOrder;
}
