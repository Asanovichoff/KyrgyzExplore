package com.kyrgyzexplore.booking.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class RejectBookingRequest {

    @NotBlank(message = "A rejection reason is required")
    @Size(max = 500, message = "Reason must not exceed 500 characters")
    private String reason;
}
