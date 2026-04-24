package com.kyrgyzexplore.listing;

import com.kyrgyzexplore.common.exception.AppException;
import com.kyrgyzexplore.listing.dto.*;
import lombok.RequiredArgsConstructor;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ListingService {

    private final ListingRepository listingRepository;
    private final ListingImageRepository listingImageRepository;
    private final S3Service s3Service;

    // SRID 4326 = WGS84 (same coordinate system as GPS / PostGIS geometry column)
    private static final GeometryFactory GEOMETRY_FACTORY = new GeometryFactory(new PrecisionModel(), 4326);

    @Transactional
    public ListingResponse create(CreateListingRequest req, UUID hostId) {
        // JTS Coordinate is (x, y) = (longitude, latitude)
        Point location = GEOMETRY_FACTORY.createPoint(new Coordinate(req.getLongitude(), req.getLatitude()));

        Listing listing = Listing.builder()
                .hostId(hostId)
                .type(req.getType())
                .title(req.getTitle())
                .description(req.getDescription())
                .pricePerUnit(req.getPricePerUnit())
                .currency(req.getCurrency() != null ? req.getCurrency() : "USD")
                .maxGuests(req.getMaxGuests())
                .location(location)
                .address(req.getAddress())
                .city(req.getCity())
                .build();

        return toResponse(listingRepository.save(listing));
    }

    @Transactional(readOnly = true)
    public ListingResponse findById(UUID id) {
        Listing listing = listingRepository.findByIdAndDeletedAtIsNull(id)
                .orElseThrow(() -> AppException.notFound("LISTING_NOT_FOUND", "Listing not found"));
        return toResponse(listing);
    }

    @Transactional
    public ListingResponse update(UUID id, UpdateListingRequest req, UUID hostId) {
        Listing listing = loadAndVerifyOwner(id, hostId);

        if (req.getTitle() != null) listing.setTitle(req.getTitle());
        if (req.getDescription() != null) listing.setDescription(req.getDescription());
        if (req.getPricePerUnit() != null) listing.setPricePerUnit(req.getPricePerUnit());
        if (req.getCurrency() != null) listing.setCurrency(req.getCurrency());
        if (req.getMaxGuests() != null) listing.setMaxGuests(req.getMaxGuests());
        if (req.getAddress() != null) listing.setAddress(req.getAddress());
        if (req.getCity() != null) listing.setCity(req.getCity());

        if (req.getLatitude() != null && req.getLongitude() != null) {
            listing.setLocation(GEOMETRY_FACTORY.createPoint(
                    new Coordinate(req.getLongitude(), req.getLatitude())));
        }

        return toResponse(listingRepository.save(listing));
    }

    @Transactional
    public void softDelete(UUID id, UUID hostId) {
        Listing listing = loadAndVerifyOwner(id, hostId);
        listing.setDeletedAt(Instant.now());
        listingRepository.save(listing);
    }

    @Transactional(readOnly = true)
    public Page<ListingResponse> findByHost(UUID hostId, Pageable pageable) {
        return listingRepository.findByHostIdAndDeletedAtIsNull(hostId, pageable)
                .map(this::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<ListingResponse> search(
            double lat, double lon, double radiusKm,
            ListingType type, BigDecimal minPrice, BigDecimal maxPrice,
            String city, Integer minGuests,
            int page, int size) {

        double radiusMeters = radiusKm * 1000.0;
        String typeStr = type != null ? type.name() : null;
        // Cap page size at 50 — prevents clients from requesting huge result sets
        PageRequest pr = PageRequest.of(page, Math.min(size, 50));

        return listingRepository
                .searchListings(lat, lon, radiusMeters, typeStr, minPrice, maxPrice, city, minGuests, pr)
                .map(listing -> {
                    double dist = haversineDistanceKm(lat, lon,
                            listing.getLocation().getY(),
                            listing.getLocation().getX());
                    double rounded = Math.round(dist * 10.0) / 10.0;
                    return toResponse(listing).toBuilder().distanceKm(rounded).build();
                });
    }

    // Haversine formula — accurate to ~0.3% for distances under 500 km
    private static double haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
        final double R = 6371.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                 + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                 * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    public PresignResponse generateImageUploadUrl(UUID listingId, UUID hostId) {
        loadAndVerifyOwner(listingId, hostId);
        String s3Key = "listings/" + listingId + "/" + UUID.randomUUID();
        return new PresignResponse(s3Service.generatePresignedPutUrl(s3Key), s3Key);
    }

    @Transactional
    public ListingImageResponse confirmImage(UUID listingId, String s3Key, UUID hostId) {
        Listing listing = loadAndVerifyOwner(listingId, hostId);

        short displayOrder = (short) listing.getImages().size();
        ListingImage image = ListingImage.builder()
                .listing(listing)
                .s3Key(s3Key)
                .displayOrder(displayOrder)
                .build();

        return toImageResponse(listingImageRepository.save(image));
    }

    private Listing loadAndVerifyOwner(UUID id, UUID hostId) {
        Listing listing = listingRepository.findByIdAndDeletedAtIsNull(id)
                .orElseThrow(() -> AppException.notFound("LISTING_NOT_FOUND", "Listing not found"));
        if (!listing.getHostId().equals(hostId)) {
            throw AppException.forbidden("LISTING_FORBIDDEN", "You do not own this listing");
        }
        return listing;
    }

    private ListingResponse toResponse(Listing listing) {
        List<ListingImageResponse> images = listing.getImages().stream()
                .map(this::toImageResponse)
                .toList();

        return ListingResponse.builder()
                .id(listing.getId())
                .hostId(listing.getHostId())
                .type(listing.getType())
                .title(listing.getTitle())
                .description(listing.getDescription())
                .pricePerUnit(listing.getPricePerUnit())
                .currency(listing.getCurrency())
                .maxGuests(listing.getMaxGuests())
                .latitude(listing.getLocation().getY())
                .longitude(listing.getLocation().getX())
                .address(listing.getAddress())
                .city(listing.getCity())
                .country(listing.getCountry())
                .averageRating(listing.getAverageRating())
                .reviewCount(listing.getReviewCount())
                .isActive(listing.isActive())
                .images(images)
                .createdAt(listing.getCreatedAt())
                .updatedAt(listing.getUpdatedAt())
                .build();
    }

    private ListingImageResponse toImageResponse(ListingImage image) {
        return new ListingImageResponse(
                image.getId(),
                s3Service.generatePresignedGetUrl(image.getS3Key()),
                image.getDisplayOrder()
        );
    }
}
