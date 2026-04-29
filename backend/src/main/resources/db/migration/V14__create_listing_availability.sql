-- Stores dates that a host has manually blocked (e.g. maintenance, personal use).
-- Booking-derived blocked dates are computed at query time from the bookings table —
-- they are NOT stored here. This table only tracks host-managed overrides.
CREATE TABLE listing_availability (
    id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id  UUID    NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    date        DATE    NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Uniqueness: a date can only be manually blocked once per listing
CREATE UNIQUE INDEX idx_listing_availability_listing_date ON listing_availability(listing_id, date);
CREATE INDEX        idx_listing_availability_listing_id   ON listing_availability(listing_id);