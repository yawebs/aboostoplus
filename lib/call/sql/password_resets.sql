-- Password reset by emailed code (password-reset.php). Run once on the live database.

-- One row per code sent. Only hashes are stored: the 6-digit code and the
-- reset token never touch the database in plain text.
CREATE TABLE IF NOT EXISTS password_resets (
  id                  INT AUTO_INCREMENT PRIMARY KEY,
  user_id             INT          NOT NULL,          -- users.id
  email               VARCHAR(190) NOT NULL,
  code_hash           VARCHAR(255) NOT NULL,          -- password_hash() of the 6-digit code
  attempts            TINYINT      NOT NULL DEFAULT 0, -- wrong guesses; locked at 5
  expires_at          DATETIME     NOT NULL,           -- code lifetime (15 min)
  reset_token_hash    CHAR(64)     NULL,               -- sha256 of the token issued after a correct code
  reset_token_expires DATETIME     NULL,
  used_at             DATETIME     NULL,               -- set once the password is changed
  request_ip          VARCHAR(45)  NULL,
  created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_pr_email (email, created_at),
  INDEX idx_pr_ip (request_ip, created_at),
  INDEX idx_pr_token (reset_token_hash)
);
