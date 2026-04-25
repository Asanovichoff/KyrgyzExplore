ALTER TABLE bookings ADD COLUMN stripe_payment_intent_id VARCHAR(255);
ALTER TABLE bookings ADD COLUMN paid_at TIMESTAMPTZ;

-- Unique partial index: fast lookup by payment intent ID, only for rows that have one.
CREATE UNIQUE INDEX idx_bookings_payment_intent
    ON bookings(stripe_payment_intent_id)
    WHERE stripe_payment_intent_id IS NOT NULL;

-- Extend the V8 status transition guard to allow CONFIRMED → PAID and PAID → CANCELLED.
-- CREATE OR REPLACE replaces the function body in place — the trigger from V8 still points
-- to the same function name so no trigger drop/recreate is needed.
CREATE OR REPLACE FUNCTION enforce_booking_status_transition()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = NEW.status THEN RETURN NEW; END IF;

    IF OLD.status IN ('REJECTED', 'CANCELLED') THEN
        RAISE EXCEPTION
            'Illegal booking transition: booking % is already % (terminal)',
            OLD.id, OLD.status;
    END IF;

    IF OLD.status = 'CONFIRMED' AND NEW.status NOT IN ('CANCELLED', 'PAID') THEN
        RAISE EXCEPTION
            'Illegal booking transition: % → % is not allowed',
            OLD.status, NEW.status;
    END IF;

    IF OLD.status = 'PAID' AND NEW.status != 'CANCELLED' THEN
        RAISE EXCEPTION
            'Illegal booking transition: % → % is not allowed',
            OLD.status, NEW.status;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
