CREATE TABLE IF NOT EXISTS user_balance_query_keys (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    key_hash CHAR(64) NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_balance_query_keys_hash
    ON user_balance_query_keys (key_hash)
    WHERE key_hash <> '';
