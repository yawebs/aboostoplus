-- Agent verification (agent-verification.php + admin "Verifications" tab).
-- Run once on the live database.

-- The badge flag. Only an admin approval sets it to 1.
ALTER TABLE users
  ADD COLUMN is_verified TINYINT(1) NOT NULL DEFAULT 0,
  ADD COLUMN verified_at DATETIME NULL;

-- One row per submission. Agents can resubmit after a rejection, so the
-- latest row per user is the current one.
CREATE TABLE IF NOT EXISTS agent_verifications (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  user_id          INT          NOT NULL,          -- users.id
  user_uid         VARCHAR(100) NOT NULL,          -- users.uniqueId
  legal_name       VARCHAR(150) NOT NULL,
  business_name    VARCHAR(150) NULL,
  office_address   VARCHAR(255) NOT NULL,
  state            VARCHAR(60)  NOT NULL,
  cac_number       VARCHAR(40)  NULL,
  id_type          VARCHAR(40)  NOT NULL,          -- nin | drivers_licence | passport | voters_card
  id_number        VARCHAR(40)  NOT NULL,
  id_front         VARCHAR(120) NOT NULL,          -- file names inside uploads/verification/
  id_back          VARCHAR(120) NULL,
  selfie           VARCHAR(120) NOT NULL,
  status           ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  rejection_reason VARCHAR(500) NULL,
  created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at      DATETIME     NULL,
  reviewed_by      INT          NULL,
  INDEX idx_av_user (user_id),
  INDEX idx_av_status (status, created_at)
);
