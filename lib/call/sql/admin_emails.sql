-- Admin email broadcasts (admin dashboard → Emails tab). Run once on the live database.

-- People who clicked "Unsubscribe" in a broadcast email are skipped in future broadcasts.
ALTER TABLE users
  ADD COLUMN email_opt_out TINYINT(1) NOT NULL DEFAULT 0;

-- One row per send, shown as history on the Emails tab.
CREATE TABLE IF NOT EXISTS admin_email_log (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  admin_id    INT          NULL,
  admin_name  VARCHAR(120) NULL,
  audience    VARCHAR(20)  NOT NULL,          -- all | agents | users | single | test
  subject     VARCHAR(200) NOT NULL,
  recipients  INT          NOT NULL DEFAULT 0,
  sent        INT          NOT NULL DEFAULT 0,
  failed      INT          NOT NULL DEFAULT 0,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_ael_created (created_at)
);
