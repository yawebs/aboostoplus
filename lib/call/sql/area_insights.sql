-- Cache for AI area insights (area-insights.php): one row per
-- community|city|state, refreshed after 30 days. Without this table the
-- endpoint still works but calls the AI on every view.

CREATE TABLE IF NOT EXISTS area_insights (
  area_key   VARCHAR(255) NOT NULL PRIMARY KEY,
  payload    MEDIUMTEXT   NOT NULL,
  created_at DATETIME     NOT NULL
);
