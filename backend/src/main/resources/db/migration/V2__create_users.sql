-- V2: Users and refresh tokens.
-- WHY VARCHAR for email instead of CITEXT?
-- Hibernate's schema validation doesn't recognize PostgreSQL's citext type
-- (it maps to JDBC Types#OTHER, not VARCHAR). We normalize email to lowercase
-- in the application layer (AuthService), so UNIQUE + VARCHAR gives us the
-- same guarantee without the Hibernate friction.
--
-- WHY VARCHAR(20) instead of a PostgreSQL ENUM for role?
-- PostgreSQL enums require ALTER TYPE to add new values, which locks the table.
-- VARCHAR with application-level validation is easier to evolve.

CREATE TABLE users (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    email             VARCHAR(255) NOT NULL UNIQUE,
    password_hash     TEXT        NOT NULL,
    role              VARCHAR(20) NOT NULL DEFAULT 'TRAVELER',
    first_name        VARCHAR(100) NOT NULL,
    last_name         VARCHAR(100) NOT NULL,
    phone             VARCHAR(30),
    profile_image_url TEXT,
    stripe_account_id TEXT,
    is_active         BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role  ON users(role);

-- Refresh tokens: DB table is the audit log. Active tokens also live in Redis.
-- token_hash stores SHA-256(raw_token) — never the raw token itself.
-- If this table is leaked, attackers cannot use the hashes to log in.
CREATE TABLE refresh_tokens (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT        NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user_id    ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);
