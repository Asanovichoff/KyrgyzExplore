package com.kyrgyzexplore.listing;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * Stores the S3 key for each listing photo.
 * We never store S3 URLs — only keys. URLs are generated on-the-fly from keys
 * because signed URLs expire, and the base URL can change (e.g. if we add CloudFront).
 * Storing the key gives us flexibility; storing the URL locks us in.
 */
@Entity
@Table(name = "listing_images")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ListingImage {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "listing_id", nullable = false)
    private Listing listing;

    // Explicit name: SpringPhysicalNamingStrategy converts "s3Key" → "s3key" (no underscore
    // at digit→uppercase), but the DB column is "s3_key". Override to match exactly.
    @Column(name = "s3_key", nullable = false, columnDefinition = "TEXT")
    private String s3Key;

    @Column(nullable = false)
    @Builder.Default
    private short displayOrder = 0;

    @CreationTimestamp
    @Column(updatable = false, nullable = false)
    private Instant createdAt;
}
