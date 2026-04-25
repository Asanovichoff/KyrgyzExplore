package com.kyrgyzexplore.booking;

import com.kyrgyzexplore.booking.dto.BookingResponse;
import com.kyrgyzexplore.booking.dto.CreateBookingRequest;
import com.kyrgyzexplore.booking.dto.RejectBookingRequest;
import com.kyrgyzexplore.common.dto.ApiResponse;
import com.kyrgyzexplore.payment.dto.PaymentIntentResponse;
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
@RequestMapping("/api/v1/bookings")
@RequiredArgsConstructor
public class BookingController {

    private final BookingService bookingService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasRole('TRAVELER')")
    public ApiResponse<BookingResponse> create(
            @RequestBody @Valid CreateBookingRequest req,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(bookingService.create(currentUser.getId(), req));
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ApiResponse<BookingResponse> getById(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(bookingService.getById(id, currentUser.getId()));
    }

    @GetMapping("/my")
    @PreAuthorize("hasRole('TRAVELER')")
    public ApiResponse<Page<BookingResponse>> myBookings(
            @PageableDefault(size = 20) Pageable pageable,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(bookingService.getMyBookings(currentUser.getId(), pageable));
    }

    @GetMapping("/host")
    @PreAuthorize("hasRole('HOST')")
    public ApiResponse<Page<BookingResponse>> hostBookings(
            @PageableDefault(size = 20) Pageable pageable,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(bookingService.getHostBookings(currentUser.getId(), pageable));
    }

    @PostMapping("/{id}/confirm")
    @PreAuthorize("hasRole('HOST')")
    public ApiResponse<BookingResponse> confirm(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(bookingService.confirm(id, currentUser.getId()));
    }

    @PostMapping("/{id}/reject")
    @PreAuthorize("hasRole('HOST')")
    public ApiResponse<BookingResponse> reject(
            @PathVariable UUID id,
            @RequestBody @Valid RejectBookingRequest req,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(bookingService.reject(id, currentUser.getId(), req.getReason()));
    }

    @PostMapping("/{id}/cancel")
    @PreAuthorize("isAuthenticated()")
    public ApiResponse<BookingResponse> cancel(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(bookingService.cancel(id, currentUser.getId()));
    }

    @PostMapping("/{id}/pay")
    @PreAuthorize("hasRole('TRAVELER')")
    public ApiResponse<PaymentIntentResponse> pay(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(bookingService.initiatePayment(id, currentUser.getId()));
    }
}
