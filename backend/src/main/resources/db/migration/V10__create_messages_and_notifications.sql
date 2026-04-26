-- ──────────────────────────────────────────────────────────────────────────
-- Phase 7 — Messaging & Notifications
-- One message thread per booking (traveler ↔ host), plus persisted notifications.
-- ──────────────────────────────────────────────────────────────────────────

-- ── Messages ──────────────────────────────────────────────────────────────
-- ON DELETE RESTRICT on booking_id: we never want to delete a booking that
-- has conversation history — this forces an explicit decision if we ever try.
CREATE TABLE messages (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id  UUID        NOT NULL REFERENCES bookings(id) ON DELETE RESTRICT,
    sender_id   UUID        NOT NULL REFERENCES users(id)    ON DELETE RESTRICT,
    content     TEXT        NOT NULL,
    is_read     BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_booking_id ON messages(booking_id);
CREATE INDEX idx_messages_sender_id  ON messages(sender_id);

-- ── Notifications ─────────────────────────────────────────────────────────
-- ON DELETE CASCADE on recipient_id: deleting a user removes their notifications.
-- ON DELETE SET NULL on related_booking_id: the notification survives even if
--   the booking is deleted (e.g. hard-deleted in an admin cleanup).
CREATE TABLE notifications (
    id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id        UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type                VARCHAR(50)  NOT NULL,
    title               VARCHAR(255) NOT NULL,
    body                TEXT         NOT NULL,
    related_booking_id  UUID         REFERENCES bookings(id) ON DELETE SET NULL,
    is_read             BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_recipient_id ON notifications(recipient_id);

-- Partial index: only indexes unread rows, making "how many unread?" very fast.
-- Once a notification is marked read it drops out of this index automatically.
CREATE INDEX idx_notifications_unread
    ON notifications(recipient_id, is_read)
    WHERE is_read = FALSE;
