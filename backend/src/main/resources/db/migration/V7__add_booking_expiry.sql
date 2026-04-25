-- PENDING bookings that are never confirmed/paid should free their dates after 24 hours.
-- expires_at is only meaningful for PENDING bookings; it is NULL for all other statuses.
ALTER TABLE bookings ADD COLUMN expires_at TIMESTAMPTZ;

-- Back-fill: existing PENDING rows get a 24-hour window from when they were created.
-- Already-terminal rows (CONFIRMED, REJECTED, CANCELLED) stay NULL.
UPDATE bookings SET expires_at = created_at + INTERVAL '24 hours' WHERE status = 'PENDING';

-- The availability conflict query filters on expires_at for PENDING rows.
-- Including it in this index lets Postgres evaluate the expiry condition cheaply.
DROP INDEX IF EXISTS idx_bookings_availability;
CREATE INDEX idx_bookings_availability
    ON bookings(listing_id, check_in_date, check_out_date)
    WHERE status IN ('PENDING', 'CONFIRMED');
