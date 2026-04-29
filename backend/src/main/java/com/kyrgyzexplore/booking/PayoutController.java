package com.kyrgyzexplore.booking;

import com.kyrgyzexplore.booking.dto.PayoutResponse;
import com.kyrgyzexplore.common.dto.ApiResponse;
import com.kyrgyzexplore.listing.ListingRepository;
import com.kyrgyzexplore.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/payouts")
@RequiredArgsConstructor
public class PayoutController {

    private final BookingRepository bookingRepository;
    private final ListingRepository listingRepository;

    @GetMapping
    @PreAuthorize("hasRole('HOST')")
    public ApiResponse<Page<PayoutResponse>> getPayouts(
            @PageableDefault(size = 20) Pageable pageable,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(
            bookingRepository.findPaidByHostId(currentUser.getId(), pageable)
                .map(b -> {
                    String title = listingRepository.findById(b.getListingId())
                            .map(l -> l.getTitle())
                            .orElse("Unknown listing");
                    return PayoutResponse.builder()
                            .bookingId(b.getId())
                            .listingTitle(title)
                            .checkInDate(b.getCheckInDate())
                            .checkOutDate(b.getCheckOutDate())
                            .totalAmount(b.getTotalPrice())
                            .paidAt(b.getPaidAt())
                            .build();
                })
        );
    }
}
