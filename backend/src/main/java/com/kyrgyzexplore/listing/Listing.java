package com.kyrgyzexplore.listing;

import com.kyrgyzexplore.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;
import org.locationtech.jts.geom.Point;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * WHY use org.locationtech.jts.geom.Point for location?
 * Hibernate Spatial (already in pom.xml) bridges between Java and PostGIS.
 * The JTS Point type maps to GEOMETRY(Point, 4326) in PostgreSQL and lets us
 * run spatial queries like ST_DWithin directly from JPA @Query methods.
 *
 * WHY store latitude/longitude as a geometry instead of two FLOAT columns?
 * Two float columns are fine for display, but useless for proximity queries.
 * A spatial column with a GiST index lets the DB find "all listings within 10km"
 * in milliseconds even with millions of rows.
 */
@Entity
@Table(name = "listings")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Listing extends BaseEntity {

    @Column(nullable = false)
    private UUID hostId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ListingType type;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal pricePerUnit;

    @Column(nullable = false, length = 3)
    @Builder.Default
    private String currency = "USD";

    private Integer maxGuests;

    // WGS84 coordinate system (same as GPS). x = longitude, y = latitude.
    @Column(nullable = false, columnDefinition = "geometry(Point, 4326)")
    private Point location;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String address;

    @Column(nullable = false, length = 100)
    private String city;

    @Column(nullable = false, length = 100)
    @Builder.Default
    private String country = "Kyrgyzstan";

    @Column(precision = 3, scale = 2)
    private BigDecimal averageRating;

    @Column(nullable = false)
    @Builder.Default
    private int reviewCount = 0;

    @Column(nullable = false)
    @Builder.Default
    private boolean isActive = true;

    private Instant deletedAt;

    @OneToMany(mappedBy = "listing", cascade = CascadeType.ALL, orphanRemoval = true,
               fetch = FetchType.LAZY)
    @OrderBy("displayOrder ASC")
    @Builder.Default
    private List<ListingImage> images = new ArrayList<>();

    public boolean isDeleted() {
        return deletedAt != null;
    }
}
