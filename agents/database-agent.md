# Database Agent — KyrgyzExplore

## Your Role
You are the **Database Agent** for KyrgyzExplore. You own the database schema, all Flyway
migrations, query performance, indexing strategy, and data integrity. You do not write Java or
Dart code. When the Backend Agent needs a new table or index, they submit a request via
`HANDOFF.md` and you write the migration.

## Your Domain (Files You Own)
```
database/
├── CLAUDE.md
├── schema.sql                  ← Canonical full schema (human reference, not executed directly)
├── migrations/                 ← Flyway migration files (executed by Spring Boot on startup)
│   ├── V1__initial_schema.sql
│   ├── V2__add_postgis.sql
│   ├── V3__listings.sql
│   └── ...
├── seeds/
│   ├── dev_seed.sql            ← Sample data for local development
│   └── test_fixtures.sql       ← Fixture data for integration tests
└── queries/
    └── useful_queries.sql      ← Complex analytical queries (not used by app)
```

## What You Must NOT Do
- Do not write Java application code
- Do not write Flutter/Dart code
- Do not modify `backend/` or `frontend/` directories
- Do not use `DROP TABLE` or `DROP COLUMN` in migrations — only additive changes or soft deletes
- Do not execute `ALTER TABLE ... SET NOT NULL` without a default or backfill step

---

## Database: PostgreSQL 16 + PostGIS

### Connection (local dev)
```
Host:     localhost
Port:     5432
Database: kyrgyzexplore
Username: kyrgyz
Password: (from .env)
```

### Required Extensions
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```

---

## Migration Rules

### Naming Convention
```
V{number}__{description}.sql
V1__initial_schema.sql
V4__add_listing_search_index.sql
V7__messages_read_at_column.sql
```
- Version numbers are sequential integers (no gaps)
- Description uses underscores, lowercase
- Never rename or edit an existing migration file — add a new one

### Every Migration Must
1. Be **idempotent** where possible (use `IF NOT EXISTS`, `IF NOT EXISTS` on indexes)
2. Include a `-- Migration: V{n}` comment at the top
3. Be tested against a clean database locally before committing
4. Include rollback comments at the bottom (manual — Flyway Community doesn't auto-rollback)

### Migration Template
```sql
-- Migration: V{n}__{description}
-- Author: Database Agent
-- Date: YYYY-MM-DD
-- Purpose: [What this migration does and why]

BEGIN;

-- Your DDL here

COMMIT;

-- Rollback (manual reference only):
-- DROP TABLE IF EXISTS <table>;
-- ALTER TABLE <table> DROP COLUMN IF EXISTS <col>;
```

---

## Full Schema Reference

### ENUM Types
```sql
CREATE TYPE user_role       AS ENUM ('TRAVELER', 'HOST', 'ADMIN');
CREATE TYPE listing_type    AS ENUM ('HOUSE', 'CAR', 'ACTIVITY');
CREATE TYPE listing_status  AS ENUM ('DRAFT', 'ACTIVE', 'PAUSED', 'DELETED');
CREATE TYPE price_unit      AS ENUM ('NIGHT', 'DAY', 'PERSON');
CREATE TYPE booking_status  AS ENUM ('PENDING', 'CONFIRMED', 'ACTIVE', 'COMPLETED', 'CANCELLED');
```

### users
```sql
CREATE TABLE users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email               VARCHAR(255) UNIQUE NOT NULL,
    password_hash       VARCHAR(255),                       -- NULL for OAuth-only
    full_name           VARCHAR(120) NOT NULL,
    phone               VARCHAR(30),                        -- E.164 format
    avatar_url          TEXT,
    role                user_role NOT NULL DEFAULT 'TRAVELER',
    is_verified         BOOLEAN NOT NULL DEFAULT FALSE,
    stripe_account_id   VARCHAR(255),                       -- Stripe Connect, hosts only
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_users_email ON users(email);
```

### listings
```sql
CREATE TABLE listings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            listing_type NOT NULL,
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    location        GEOGRAPHY(POINT, 4326) NOT NULL,        -- PostGIS point (lng, lat)
    address         VARCHAR(300),
    region          VARCHAR(100),
    price_per_unit  INTEGER NOT NULL,                       -- in KGS tiyin (1 KGS = 100 tiyin)
    price_unit      price_unit NOT NULL,
    attributes      JSONB NOT NULL DEFAULT '{}',            -- type-specific fields
    is_instant_book BOOLEAN NOT NULL DEFAULT FALSE,
    status          listing_status NOT NULL DEFAULT 'DRAFT',
    avg_rating      NUMERIC(3,2) NOT NULL DEFAULT 0,
    review_count    INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- Geospatial index (critical for ST_DWithin queries)
CREATE INDEX idx_listings_location ON listings USING GIST(location);
CREATE INDEX idx_listings_host     ON listings(host_id);
CREATE INDEX idx_listings_status   ON listings(status);
CREATE INDEX idx_listings_type     ON listings(type);
```

### listing_photos
```sql
CREATE TABLE listing_photos (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id  UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    url         TEXT NOT NULL,                              -- S3 object key (not full URL)
    sort_order  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_photos_listing ON listing_photos(listing_id, sort_order);
```

### listing_availability
```sql
CREATE TABLE listing_availability (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id  UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    date        DATE NOT NULL,
    is_blocked  BOOLEAN NOT NULL DEFAULT TRUE,              -- TRUE = unavailable
    UNIQUE(listing_id, date)
);
CREATE INDEX idx_avail_listing_date ON listing_availability(listing_id, date);
```

### bookings
```sql
CREATE TABLE bookings (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id                  UUID NOT NULL REFERENCES listings(id),
    traveler_id                 UUID NOT NULL REFERENCES users(id),
    check_in                    DATE NOT NULL,
    check_out                   DATE NOT NULL,
    guests                      INTEGER NOT NULL DEFAULT 1,
    total_amount                INTEGER NOT NULL,           -- KGS tiyin
    platform_fee                INTEGER NOT NULL,           -- platform's share
    status                      booking_status NOT NULL DEFAULT 'PENDING',
    cancel_reason               TEXT,
    stripe_payment_intent_id    VARCHAR(255),
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_dates CHECK (check_out > check_in)
);
CREATE INDEX idx_bookings_listing    ON bookings(listing_id, status);
CREATE INDEX idx_bookings_traveler   ON bookings(traveler_id);
CREATE INDEX idx_bookings_dates      ON bookings(check_in, check_out);
```

### conversations & messages
```sql
CREATE TABLE conversations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id      UUID UNIQUE REFERENCES bookings(id),
    traveler_id     UUID NOT NULL REFERENCES users(id),
    host_id         UUID NOT NULL REFERENCES users(id),
    last_message_at TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_conv_traveler ON conversations(traveler_id);
CREATE INDEX idx_conv_host     ON conversations(host_id);

CREATE TABLE messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES users(id),
    body            TEXT NOT NULL,
    read_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_messages_conv ON messages(conversation_id, created_at DESC);
```

### reviews
```sql
CREATE TABLE reviews (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id  UUID NOT NULL REFERENCES bookings(id),
    author_id   UUID NOT NULL REFERENCES users(id),
    target_id   UUID NOT NULL REFERENCES users(id),     -- the reviewed user
    listing_id  UUID NOT NULL REFERENCES listings(id),
    rating      SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(booking_id, author_id)                       -- one review per side per booking
);
CREATE INDEX idx_reviews_listing ON reviews(listing_id);
CREATE INDEX idx_reviews_target  ON reviews(target_id);
```

### notifications & refresh_tokens
```sql
CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type        VARCHAR(50) NOT NULL,
    title       VARCHAR(200) NOT NULL,
    body        TEXT NOT NULL,
    payload     JSONB NOT NULL DEFAULT '{}',
    read_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_notif_user ON notifications(user_id, read_at, created_at DESC);

CREATE TABLE refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  VARCHAR(64) NOT NULL UNIQUE,             -- SHA-256 of the raw token
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_rt_token ON refresh_tokens(token_hash) WHERE NOT revoked;
```

---

## Performance Guidelines

### Indexing Rules
- Every foreign key column must have an index
- Columns used in WHERE clauses in hot queries must have an index
- `GEOGRAPHY` columns must use `GIST` index
- Composite indexes: most selective column first
- Partial indexes (e.g., `WHERE status = 'ACTIVE'`) where cardinality is low

### Query Performance Targets (MVP)
| Query | Target |
|-------|--------|
| Listing search (ST_DWithin + filters) | < 50ms |
| Booking availability check | < 20ms |
| Conversation message history (page 1) | < 10ms |
| User profile + recent reviews | < 15ms |

Run `EXPLAIN (ANALYZE, BUFFERS)` on any query that feels slow and add to `queries/useful_queries.sql`.

### Denormalization
`listings.avg_rating` and `listings.review_count` are intentionally denormalized.
Update them via a trigger after review insert/delete:
```sql
CREATE OR REPLACE FUNCTION update_listing_rating() RETURNS TRIGGER AS $$
BEGIN
    UPDATE listings SET
        avg_rating   = (SELECT COALESCE(AVG(rating), 0) FROM reviews WHERE listing_id = NEW.listing_id),
        review_count = (SELECT COUNT(*) FROM reviews WHERE listing_id = NEW.listing_id),
        updated_at   = NOW()
    WHERE id = NEW.listing_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_listing_rating
AFTER INSERT OR DELETE ON reviews
FOR EACH ROW EXECUTE FUNCTION update_listing_rating();
```

---

## Development Seeds

`database/seeds/dev_seed.sql` must provide:
- 3 host users (with hashed passwords: `password123`)
- 3 traveler users
- 5 HOUSE listings around Bishkek (lat 42.87, lng 74.59)
- 3 CAR listings
- 4 ACTIVITY listings (Issyk-Kul, Ala-Archa, Song-Kol)
- Availability blocked for past dates on all listings
- 2 completed bookings (for review system testing)

---

## Definition of Done (Database)

Before delivering any migration:
- [ ] Migration file named correctly (`V{n}__description.sql`)
- [ ] Tested on clean local database (`docker-compose down -v && docker-compose up -d`)
- [ ] All foreign keys have indexes
- [ ] `schema.sql` updated to reflect the full current schema
- [ ] Rollback comments included
- [ ] Backend Agent notified via `backend/HANDOFF.md` that migration is ready
