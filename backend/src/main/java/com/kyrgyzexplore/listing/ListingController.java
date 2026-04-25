package com.kyrgyzexplore.listing;

import com.kyrgyzexplore.common.dto.ApiResponse;
import com.kyrgyzexplore.listing.dto.*;
import com.kyrgyzexplore.user.User;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/listings")
@RequiredArgsConstructor
@Validated
public class ListingController {

    private final ListingService listingService;

    @PostMapping("/images/presign")
    @PreAuthorize("hasRole('HOST')")
    public ApiResponse<PresignResponse> presignImageUpload(
            @RequestBody @Valid PresignRequest req,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(listingService.generateImageUploadUrl(req.getListingId(), currentUser.getId()));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasRole('HOST')")
    public ApiResponse<ListingResponse> create(
            @RequestBody @Valid CreateListingRequest req,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(listingService.create(req, currentUser.getId()));
    }

    @GetMapping("/{id}")
    public ApiResponse<ListingResponse> findById(@PathVariable UUID id) {
        return ApiResponse.ok(listingService.findById(id));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('HOST')")
    public ApiResponse<ListingResponse> update(
            @PathVariable UUID id,
            @RequestBody @Valid UpdateListingRequest req,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(listingService.update(id, req, currentUser.getId()));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasRole('HOST')")
    public void delete(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser) {
        listingService.softDelete(id, currentUser.getId());
    }

    @GetMapping("/search")
    public ApiResponse<Page<ListingResponse>> search(
            @RequestParam @NotNull Double lat,
            @RequestParam @NotNull Double lon,
            @RequestParam(defaultValue = "50") @DecimalMin("0.1") @DecimalMax("100.0") Double radiusKm,
            @RequestParam(required = false) ListingType type,
            @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) Integer minGuests,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(
                listingService.search(lat, lon, radiusKm, type, minPrice, maxPrice, city, minGuests, page, size));
    }

    @GetMapping("/host/my")
    @PreAuthorize("hasRole('HOST')")
    public ApiResponse<Page<ListingResponse>> myListings(
            @PageableDefault(size = 20) Pageable pageable,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(listingService.findByHost(currentUser.getId(), pageable));
    }

    @PostMapping("/{id}/images")
    @PreAuthorize("hasRole('HOST')")
    public ApiResponse<ListingImageResponse> confirmImage(
            @PathVariable UUID id,
            @RequestBody @Valid ConfirmImageRequest req,
            @AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(listingService.confirmImage(id, req.getS3Key(), currentUser.getId()));
    }

    // ---- inner request DTOs (only used by this controller) ----

    @Getter
    @NoArgsConstructor
    static class PresignRequest {
        @NotNull(message = "listingId is required")
        private UUID listingId;
    }

    @Getter
    @NoArgsConstructor
    static class ConfirmImageRequest {
        @NotNull(message = "s3Key is required")
        private String s3Key;
    }
}
