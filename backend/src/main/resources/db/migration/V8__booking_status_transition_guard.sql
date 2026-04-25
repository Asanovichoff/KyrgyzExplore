-- Enforces the booking state machine at the DB level.
-- The service layer (BookingService.java) enforces the same rules, but this trigger
-- acts as a second line of defence against raw SQL, admin tools, and future code
-- that bypasses the service.
--
-- Valid transitions:
--   PENDING   → CONFIRMED | REJECTED | CANCELLED
--   CONFIRMED → CANCELLED
--   REJECTED  → (terminal — no transitions allowed)
--   CANCELLED → (terminal — no transitions allowed)

CREATE OR REPLACE FUNCTION enforce_booking_status_transition()
RETURNS TRIGGER AS $$
BEGIN
    -- No-op if status hasn't changed (other columns being updated)
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;

    -- Terminal states: once reached, status can never change
    IF OLD.status IN ('REJECTED', 'CANCELLED') THEN
        RAISE EXCEPTION
            'Illegal booking transition: booking % is already % (terminal)',
            OLD.id, OLD.status;
    END IF;

    -- CONFIRMED can only move to CANCELLED (not back to PENDING or REJECTED)
    IF OLD.status = 'CONFIRMED' AND NEW.status != 'CANCELLED' THEN
        RAISE EXCEPTION
            'Illegal booking transition: % → % is not allowed',
            OLD.status, NEW.status;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_booking_status_transition
    BEFORE UPDATE OF status ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION enforce_booking_status_transition();
