package com.kyrgyzexplore.common;

import com.kyrgyzexplore.common.dto.ApiResponse;
import com.kyrgyzexplore.common.dto.HealthResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
public class HealthController {

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<HealthResponse>> health() {
        return ResponseEntity.ok(ApiResponse.ok(
                HealthResponse.builder()
                        .status("UP")
                        .version("1.0.0")
                        .build()
        ));
    }
}
