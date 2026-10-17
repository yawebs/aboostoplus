-- Saved homes + search alerts. Run once against the live database.

-- A user's saved (hearted) listings.
CREATE TABLE IF NOT EXISTS saved_properties (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  user_id     VARCHAR(64) NOT NULL,
  property_id INT         NOT NULL,
  created_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_user_property (user_id, property_id),
  KEY idx_user (user_id)
);

-- Saved searches: when a newly uploaded listing matches `filters`, the user
-- gets a push notification (see call/search_alerts_lib.php).
CREATE TABLE IF NOT EXISTS search_alerts (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  user_id          VARCHAR(64)  NOT NULL,
  label            VARCHAR(160) NOT NULL,
  filters          TEXT         NOT NULL, -- JSON, same fields as the app's PropertyFilter
  active           TINYINT(1)   NOT NULL DEFAULT 1,
  created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_notified_at DATETIME     NULL,
  KEY idx_user (user_id),
  KEY idx_active (active)
);
