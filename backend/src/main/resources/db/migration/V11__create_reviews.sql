-- ──────────────────────────────────────────────────────────────────────────
-- Phase 8 — Reviews
-- One review per booking. Rating stats on the listing are recalculated by
-- ReviewService whenever a review is created or deleted.
-- ──────────────────────────────────────────────────────────────────────────

CREATE TABLE reviews (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id  UUID        NOT NULL REFERENCES listings(id)  ON DELETE CASCADE,
    traveler_id UUID        NOT NULL REFERENCES users(id)     ON DELETE RESTRICT,
    -- ON DELETE RESTRICT on booking_id: a booking with a review must not be
    -- silently deleted — force an explicit decision first.
    booking_id  UUID        NOT NULL REFERENCES bookings(id)  ON DELETE RESTRICT,
    rating      SMALLINT    NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Prevents a traveler from reviewing the same booking twice
CREATE UNIQUE INDEX idx_reviews_booking_id  ON reviews(booking_id);

CREATE INDEX idx_reviews_listing_id  ON reviews(listing_id);
CREATE INDEX idx_reviews_traveler_id ON reviews(traveler_id);
