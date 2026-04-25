CREATE TABLE bookings (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id       UUID          NOT NULL REFERENCES listings(id) ON DELETE RESTRICT,
    traveler_id      UUID          NOT NULL REFERENCES users(id)    ON DELETE RESTRICT,
    check_in_date    DATE          NOT NULL,
    check_out_date   DATE          NOT NULL,
    status           VARCHAR(20)   NOT NULL DEFAULT 'PENDING',
    number_of_guests INT           NOT NULL,
    total_price      NUMERIC(10,2) NOT NULL,
    guest_message    TEXT,
    rejection_reason TEXT,
    confirmed_at     TIMESTAMPTZ,
    rejected_at      TIMESTAMPTZ,
    cancelled_at     TIMESTAMPTZ,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_booking_dates   CHECK (check_in_date < check_out_date),
    CONSTRAINT chk_guests_positive CHECK (number_of_guests > 0)
);

CREATE INDEX idx_bookings_listing_id  ON bookings(listing_id);
CREATE INDEX idx_bookings_traveler_id ON bookings(traveler_id);
CREATE INDEX idx_bookings_status      ON bookings(status);

-- Partial index for the availability conflict query.
-- PENDING + CONFIRMED are the only statuses that block new bookings.
-- Cancelled/rejected bookings do NOT count, so they are excluded from this index.
CREATE INDEX idx_bookings_availability
    ON bookings(listing_id, check_in_date, check_out_date)
    WHERE status IN ('PENDING', 'CONFIRMED');
