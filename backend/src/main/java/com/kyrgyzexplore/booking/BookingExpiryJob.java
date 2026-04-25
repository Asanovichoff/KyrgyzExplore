package com.kyrgyzexplore.booking;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Component
@RequiredArgsConstructor
@Slf4j
public class BookingExpiryJob {

    private final BookingRepository bookingRepository;

    /**
     * Runs every 15 minutes. Finds PENDING bookings whose 24-hour window has passed
     * and marks them CANCELLED so their dates become available again.
     *
     * fixedDelay means the 15-minute countdown starts after the previous run finishes,
     * preventing overlapping executions if the DB is slow.
     */
    @Scheduled(fixedDelay = 15 * 60 * 1000)
    @Transactional
    public void cancelExpiredBookings() {
        int count = bookingRepository.cancelExpiredBookings(Instant.now());
        if (count > 0) {
            log.info("Expired {} pending booking(s)", count);
        }
    }
}
