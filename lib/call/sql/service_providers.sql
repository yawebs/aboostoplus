-- Moving & home service providers (separate from the marketplace).
-- Run once against the live database.
CREATE TABLE IF NOT EXISTS service_providers (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  owner_id       VARCHAR(64)   NOT NULL,          -- users.uniqueId
  business_name  VARCHAR(120)  NOT NULL,
  category       VARCHAR(60)   NOT NULL,          -- e.g. 'Moving & Haulage'
  description    TEXT          NOT NULL,
  state          VARCHAR(80)   NOT NULL,
  areas          VARCHAR(255)  NOT NULL,          -- areas/communities covered
  starting_price DECIMAL(15,2) NULL,
  phone          VARCHAR(20)   NOT NULL,
  images         TEXT          NOT NULL,          -- JSON array of URLs
  status         VARCHAR(20)   NOT NULL DEFAULT 'active',
  created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_category (category, status),
  KEY idx_owner (owner_id)
);
