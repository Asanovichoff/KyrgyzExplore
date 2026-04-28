CREATE TABLE device_tokens (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token       TEXT        NOT NULL,
    platform    VARCHAR(10) NOT NULL CHECK (platform IN ('android', 'ios')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Token is globally unique — one FCM token maps to exactly one device
CREATE UNIQUE INDEX idx_device_tokens_token   ON device_tokens(token);
CREATE INDEX        idx_device_tokens_user_id ON device_tokens(user_id);
