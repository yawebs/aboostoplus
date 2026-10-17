-- Links Google / Apple accounts to users rows (used by social_login.php).
-- Run once on the YOUR_DB_NAME database before deploying
-- social_login.php.
--
-- user_id is INT to match users.id; if users.id is BIGINT or UNSIGNED in
-- your schema, change it here to the same type or the foreign key fails.
CREATE TABLE IF NOT EXISTS social_identities (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT          NOT NULL,
  provider    VARCHAR(16)  NOT NULL,           -- 'google' | 'apple'
  subject     VARCHAR(255) NOT NULL,           -- the token's "sub" claim
  email       VARCHAR(255) NOT NULL DEFAULT '',
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_provider_subject (provider, subject),
  KEY idx_user (user_id),
  CONSTRAINT fk_social_identities_user
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
