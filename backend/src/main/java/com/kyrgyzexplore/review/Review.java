package com.kyrgyzexplore.review;

import com.kyrgyzexplore.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "reviews")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Review extends BaseEntity {

    @Column(nullable = false)
    private UUID listingId;

    @Column(nullable = false)
    private UUID travelerId;

    @Column(nullable = false)
    private UUID bookingId;

    @Column(nullable = false)
    private int rating;

    @Column(columnDefinition = "TEXT")
    private String comment;
}
