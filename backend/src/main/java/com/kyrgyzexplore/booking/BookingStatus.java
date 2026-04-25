package com.kyrgyzexplore.booking;

public enum BookingStatus {
    PENDING,    // created by traveler, awaiting host action
    CONFIRMED,  // host accepted
    REJECTED,   // host declined
    CANCELLED   // cancelled by traveler or host
}
