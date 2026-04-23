package com.kyrgyzexplore.listing.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class PresignResponse {
    private String uploadUrl;
    private String s3Key;
}
