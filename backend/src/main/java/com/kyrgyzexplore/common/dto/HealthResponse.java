package com.kyrgyzexplore.common.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class HealthResponse {
    private String status;
    private String version;
}
