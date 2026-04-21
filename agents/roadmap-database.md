# KyrgyzExplore — Database Agent Roadmap

> This roadmap defines every Flyway migration, in dependency order, with design decisions
> explained. The Database Agent owns `database/`. The Backend Agent reads this schema via
> Spring Data JPA — it never writes migrations.
>
> Migration naming: `V{n}__{description}.sql` (two underscores, Flyway convention)

---

## Migration Plan Overview

| Migration | File | Unblocks |
|---|---|---|
| V1 | `V1__bootstrap_extensions_and_users.sql` | Auth (Phase 2) |
| V2 | `V2__create_listings.sql` | Listings CRUD (Phase 3) |
| V3 | `V3__create_bookings_and_availability.sql` | Bookings (Phase 5) |
| V4 | `V4__create_payments.sql` | Payments (Phase 6) |
| V5 | `V5__create_messages.sql` | Messaging (Phase 7) |
| V6 | `V6__create_reviews.sql` | Reviews (Phase 8) |
| V7 | `V7__create_notifications.sql` | Push Notifications (Phase 9) |

---

## V1 — Bootstrap Extensions & Users
**File:** `V1__bootstrap_extensions_and_users.sql`

**Why first:** Everything depends on users. Extensions must be installed before any spatial or
UUID-generating columns can be created.

```sql
-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "postgis";      -- spatial queries
CREATE EXTENSION IF NOT EXISTS "citext";       -- case-insensitive email

-- Enum types
CREATE TYPE user_role AS ENUM ('TRAVELER', 'HOST', 'ADMIN');

-- Users table
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           CITEXT NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    role            user_role NOT NULL DEFAULT 'TRAVELER',
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    phone           VARCHAR(30),
    profile_image_url TEXT,
    stripe_account_id TEXT,        -- Stripe Connect account (HOST only)
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role  ON users(role);

-- Refresh tokens (stored in Redis, but this table is the authoritative log)
CREATE TABLE refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT NOT NULL UNIQUE,   -- SHA-256 of the raw token
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked_at  TIMESTAMPTZ,            -- NULL = still valid
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user_id    ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);
```

**Key design decisions:**
- `CITEXT` for email: enforces case-insensitive uniqueness at DB level (no `LOWER()` needed)
- `stripe_account_id` on users: Stripe Connect account ID, populated when host completes onboarding
- `refresh_tokens` table: acts as an audit log even though active tokens live in Redis
- `is_active` soft-delete pattern: suspended users are deactivated, not deleted

**Unblocks:** Backend Phase 2 (Auth)

---

## V2 — Listings & Images
**File:** `V2__create_listings.sql`

**Why after V1:** Listings have a `host_id` foreign key to `users`.

```sql
-- Enum types
CREATE TYPE listing_type AS ENUM ('HOUSE', 'CAR', 'ACTIVITY');

-- Listings table
CREATE TABLE listings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id         UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    type            listing_type NOT NULL,
    title           VARCHAR(200) NOT NULL,
    description     TEXT NOT NULL,
    price_per_unit  NUMERIC(10, 2) NOT NULL,   -- per night (HOUSE), per day (CAR/ACTIVITY)
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    max_guests      INT,                        -- HOUSE only
    location        GEOMETRY(Point, 4326) NOT NULL,  -- PostGIS WGS84 lat/lng
    address         TEXT NOT NULL,
    city            VARCHAR(100) NOT NULL,
    country         VARCHAR(100) NOT NULL DEFAULT 'Kyrgyzstan',
    average_rating  NUMERIC(3, 2),             -- updated on new review
    review_count    INT NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    deleted_at      TIMESTAMPTZ,               -- soft delete
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Spatial index: critical for ST_DWithin proximity queries
CREATE INDEX idx_listings_location  ON listings USING GIST(location);
CREATE INDEX idx_listings_host_id   ON listings(host_id);
CREATE INDEX idx_listings_type      ON listings(type);
CREATE INDEX idx_listings_city      ON listings(city);
-- Partial index: only active, non-deleted listings are ever queried publicly
CREATE INDEX idx_listings_active    ON listings(id) WHERE is_active = TRUE AND deleted_at IS NULL;

-- Listing images
CREATE TABLE listing_images (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id    UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    s3_key        TEXT NOT NULL,
    display_order SMALLINT NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_listing_images_listing_id ON listing_images(listing_id);
```

**Key design decisions:**
- `GEOMETRY(Point, 4326)`: WGS84 coordinate system (same as GPS/Google Maps), enables all PostGIS geo queries
- GiST index on `location`: mandatory for `ST_DWithin` to be fast (without it, full table scan)
- `price_per_unit` not `price_per_night`/`price_per_day`: unified column works for all listing types
- `deleted_at` soft delete: listings are never hard-deleted (audit trail, booking history integrity)
- `average_rating` denormalized onto listing: avoids expensive JOIN + AVG on every search result

**Unblocks:** Backend Phase 3 (Listings CRUD), Phase 4 (Search)

---

## V3 — Bookings & Availability
**File:** `V3__create_bookings_and_availability.sql`

**Why after V2:** Bookings reference both `users` (traveler) and `listings`.

```sql
-- Enum types
CREATE TYPE booking_status AS ENUM ('PENDING', 'CONFIRMED', 'COMPLETED', 'CANCELLED');

-- Bookings table
CREATE TABLE bookings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id      UUID NOT NULL REFERENCES listings(id) ON DELETE RESTRICT,
    traveler_id     UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    check_in        DATE NOT NULL,
    check_out       DATE NOT NULL,
    total_price     NUMERIC(10, 2) NOT NULL,
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    status          booking_status NOT NULL DEFAULT 'PENDING',
    guest_count     INT NOT NULL DEFAULT 1,
    host_notes      TEXT,       -- host can add notes when confirming
    cancelled_at    TIMESTAMPTZ,
    cancelled_by    UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT check_dates CHECK (check_out > check_in)
);

CREATE INDEX idx_bookings_listing_id   ON bookings(listing_id);
CREATE INDEX idx_bookings_traveler_id  ON bookings(traveler_id);
CREATE INDEX idx_bookings_status       ON bookings(status);
-- Date range index: used by overlap detection query
CREATE INDEX idx_bookings_date_range   ON bookings(listing_id, check_in, check_out)
    WHERE status IN ('PENDING', 'CONFIRMED');

-- Host-managed availability overrides (block/unblock specific dates)
CREATE TABLE availabilities (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id  UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    date        DATE NOT NULL,
    is_blocked  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(listing_id, date)
);

CREATE INDEX idx_availabilities_listing_date ON availabilities(listing_id, date);
```

**Key design decisions:**
- Booking overlap detection query: `WHERE listing_id = ? AND status IN ('PENDING','CONFIRMED') AND check_in < :checkOut AND check_out > :checkIn`
- Partial index on bookings only for active statuses: overlap queries only care about live bookings
- `availabilities` table: separate from bookings — lets hosts block dates without a booking (e.g. personal use)
- `CHECK (check_out > check_in)`: DB-level constraint catches invalid dates before app logic
- `cancelled_by` FK: audit trail for who cancelled

**Unblocks:** Backend Phase 5 (Bookings)

---

## V4 — Payments
**File:** `V4__create_payments.sql`

**Why after V3:** Every payment references a booking.

```sql
CREATE TYPE payment_status AS ENUM ('PENDING', 'SUCCEEDED', 'FAILED', 'REFUNDED');

CREATE TABLE payments (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id              UUID NOT NULL REFERENCES bookings(id) ON DELETE RESTRICT,
    stripe_payment_intent_id TEXT NOT NULL UNIQUE,
    stripe_charge_id        TEXT,
    amount                  NUMERIC(10, 2) NOT NULL,
    platform_fee            NUMERIC(10, 2) NOT NULL,
    host_payout_amount      NUMERIC(10, 2) NOT NULL,
    currency                CHAR(3) NOT NULL DEFAULT 'USD',
    status                  payment_status NOT NULL DEFAULT 'PENDING',
    stripe_transfer_id      TEXT,           -- populated when payout is sent
    refunded_at             TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_booking_id ON payments(booking_id);
CREATE INDEX idx_payments_stripe_pi  ON payments(stripe_payment_intent_id);
CREATE INDEX idx_payments_status     ON payments(status);
```

**Key design decisions:**
- `platform_fee` and `host_payout_amount` stored explicitly: financial audit trail, never recompute from current rates
- `stripe_payment_intent_id` unique: prevents duplicate payment records from webhook retries
- Separate `stripe_transfer_id`: populated asynchronously when Stripe processes the payout

**Unblocks:** Backend Phase 6 (Payments)

---

## V5 — Messaging
**File:** `V5__create_messages.sql`

**Why after V1:** Threads and messages both reference `users`.

```sql
CREATE TABLE message_threads (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id  UUID REFERENCES listings(id) ON DELETE SET NULL,
    traveler_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    host_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(listing_id, traveler_id, host_id)   -- one thread per traveler+host+listing combo
);

CREATE INDEX idx_threads_traveler_id ON message_threads(traveler_id);
CREATE INDEX idx_threads_host_id     ON message_threads(host_id);

CREATE TABLE messages (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id   UUID NOT NULL REFERENCES message_threads(id) ON DELETE CASCADE,
    sender_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content     TEXT NOT NULL,
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_thread_id ON messages(thread_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
-- Unread count query index
CREATE INDEX idx_messages_unread    ON messages(thread_id, is_read) WHERE is_read = FALSE;
```

**Key design decisions:**
- `UNIQUE(listing_id, traveler_id, host_id)`: one conversation thread per context — prevents duplicates
- `listing_id` nullable (`SET NULL` on delete): thread persists even if listing is deleted
- Partial index on unread messages: unread count badge query is very frequent

**Unblocks:** Backend Phase 7 (Messaging)

---

## V6 — Reviews
**File:** `V6__create_reviews.sql`

**Why after V3:** Reviews reference `bookings`. Can only be written after a booking is COMPLETED.

```sql
CREATE TABLE reviews (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id  UUID NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE RESTRICT,
    listing_id  UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating      SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reviews_listing_id  ON reviews(listing_id);
CREATE INDEX idx_reviews_reviewer_id ON reviews(reviewer_id);

-- Trigger: recompute average_rating and review_count on listings after insert
CREATE OR REPLACE FUNCTION update_listing_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE listings
    SET
        average_rating = (SELECT AVG(rating)::NUMERIC(3,2) FROM reviews WHERE listing_id = NEW.listing_id),
        review_count   = (SELECT COUNT(*) FROM reviews WHERE listing_id = NEW.listing_id)
    WHERE id = NEW.listing_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_listing_rating
AFTER INSERT ON reviews
FOR EACH ROW EXECUTE FUNCTION update_listing_rating();
```

**Key design decisions:**
- `UNIQUE` on `booking_id`: enforces one-review-per-booking at DB level — business rule is critical
- Trigger to update `average_rating` on listings: keeps denormalized value consistent automatically
- `rating CHECK (1-5)`: DB constraint, not just app validation

**Unblocks:** Backend Phase 8 (Reviews)

---

## V7 — Notifications & Device Tokens
**File:** `V7__create_notifications.sql`

```sql
CREATE TYPE notification_type AS ENUM (
    'BOOKING_REQUEST', 'BOOKING_CONFIRMED', 'BOOKING_CANCELLED',
    'BOOKING_COMPLETED', 'NEW_MESSAGE', 'REVIEW_RECEIVED', 'PAYOUT_SENT'
);

CREATE TABLE device_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token   TEXT NOT NULL,
    platform    VARCHAR(10) NOT NULL CHECK (platform IN ('IOS', 'ANDROID')),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(user_id, platform)   -- one token per user per platform
);

CREATE INDEX idx_device_tokens_user_id ON device_tokens(user_id);

CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            notification_type NOT NULL,
    title           VARCHAR(200) NOT NULL,
    body            TEXT NOT NULL,
    reference_id    UUID,        -- booking_id, message_id, etc. for deep linking
    reference_type  VARCHAR(50), -- 'BOOKING', 'MESSAGE', etc.
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_unread  ON notifications(user_id, is_read) WHERE is_read = FALSE;
```

**Key design decisions:**
- `UNIQUE(user_id, platform)`: upsert on token registration — device tokens rotate, not accumulate
- `reference_id` + `reference_type`: polymorphic link for deep-link navigation on tap
- Partial index on unread: notification badge count is queried on every app open

**Unblocks:** Backend Phase 9 (Push Notifications)

---

## Complete Schema ERD

```
users
├── id (PK)
├── email (UNIQUE, CITEXT)
├── password_hash
├── role (TRAVELER | HOST | ADMIN)
├── first_name, last_name, phone
├── profile_image_url
├── stripe_account_id
├── is_active
└── created_at, updated_at

refresh_tokens
├── id (PK)
├── user_id → users.id
├── token_hash (UNIQUE)
├── expires_at, revoked_at
└── created_at

listings
├── id (PK)
├── host_id → users.id
├── type (HOUSE | CAR | ACTIVITY)
├── title, description
├── price_per_unit, currency
├── max_guests
├── location (PostGIS Point WGS84) ← GiST indexed
├── address, city, country
├── average_rating, review_count   ← denormalized
├── is_active, deleted_at
└── created_at, updated_at

listing_images
├── id (PK)
├── listing_id → listings.id
├── s3_key
├── display_order
└── created_at

bookings
├── id (PK)
├── listing_id → listings.id
├── traveler_id → users.id
├── check_in, check_out (DATE)
├── total_price, currency
├── status (PENDING | CONFIRMED | COMPLETED | CANCELLED)
├── guest_count
├── cancelled_at, cancelled_by → users.id
└── created_at, updated_at

availabilities
├── id (PK)
├── listing_id → listings.id
├── date (DATE)
├── is_blocked
└── created_at

payments
├── id (PK)
├── booking_id → bookings.id
├── stripe_payment_intent_id (UNIQUE)
├── stripe_charge_id
├── amount, platform_fee, host_payout_amount, currency
├── status (PENDING | SUCCEEDED | FAILED | REFUNDED)
├── stripe_transfer_id
├── refunded_at
└── created_at, updated_at

message_threads
├── id (PK)
├── listing_id → listings.id (nullable)
├── traveler_id → users.id
├── host_id → users.id
└── created_at
UNIQUE(listing_id, traveler_id, host_id)

messages
├── id (PK)
├── thread_id → message_threads.id
├── sender_id → users.id
├── content
├── is_read
└── sent_at

reviews
├── id (PK)
├── booking_id → bookings.id (UNIQUE)
├── listing_id → listings.id
├── reviewer_id → users.id
├── rating (1-5)
├── comment
└── created_at

device_tokens
├── id (PK)
├── user_id → users.id
├── fcm_token
├── platform (IOS | ANDROID)
└── updated_at
UNIQUE(user_id, platform)

notifications
├── id (PK)
├── user_id → users.id
├── type (BOOKING_REQUEST | ... | PAYOUT_SENT)
├── title, body
├── reference_id, reference_type  (deep link target)
├── is_read
└── sent_at
```

---

## Index Strategy Summary

| Table | Key indexes | Purpose |
|---|---|---|
| users | email, role | Login lookup, role filtering |
| listings | GIST(location), host_id, type, active partial | Proximity search, host dashboard, type filter |
| bookings | listing_id+dates partial, traveler_id, status | Overlap detection, booking history |
| payments | stripe_payment_intent_id, booking_id | Webhook idempotency, booking lookup |
| messages | thread_id, unread partial | Chat load, unread count badge |
| reviews | listing_id | Reviews list on listing page |
| notifications | user_id, unread partial | Notification centre, badge count |
