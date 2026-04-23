-- V4: Listings and listing images.

CREATE TABLE listings (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id           UUID         NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    type              VARCHAR(20)  NOT NULL,
    title             VARCHAR(200) NOT NULL,
    description       TEXT         NOT NULL,
    price_per_unit    NUMERIC(10,2) NOT NULL,
    currency          CHAR(3)      NOT NULL DEFAULT 'USD',
    max_guests        INT,
    location          GEOMETRY(Point, 4326) NOT NULL,
    address           TEXT         NOT NULL,
    city              VARCHAR(100) NOT NULL,
    country           VARCHAR(100) NOT NULL DEFAULT 'Kyrgyzstan',
    average_rating    NUMERIC(3,2),
    review_count      INT          NOT NULL DEFAULT 0,
    is_active         BOOLEAN      NOT NULL DEFAULT TRUE,
    deleted_at        TIMESTAMPTZ,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- GiST index is mandatory for PostGIS proximity queries (ST_DWithin).
-- WHY GiST and not B-tree?
-- B-tree indexes work on orderable values (numbers, strings). Geometry is 2D —
-- it has no single ordering. GiST (Generalized Search Tree) understands spatial
-- relationships (overlaps, contains, within) and makes proximity queries fast.
-- Without this index, ST_DWithin does a full table scan — unacceptable at scale.
CREATE INDEX idx_listings_location ON listings USING GIST(location);
CREATE INDEX idx_listings_host_id  ON listings(host_id);
CREATE INDEX idx_listings_type     ON listings(type);
CREATE INDEX idx_listings_city     ON listings(city);
-- Partial index: search queries never touch inactive/deleted listings
CREATE INDEX idx_listings_active   ON listings(id)
    WHERE is_active = TRUE AND deleted_at IS NULL;

CREATE TABLE listing_images (
    id            UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id    UUID     NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    s3_key        TEXT     NOT NULL,
    display_order SMALLINT NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_listing_images_listing_id ON listing_images(listing_id);
