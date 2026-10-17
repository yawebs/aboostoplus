-- Adds an optional product/property reference to chat messages, so both
-- sides of a conversation can see which item is being discussed.
-- All columns are nullable: plain messages (no item) are unaffected.
-- Run once against the live database.

ALTER TABLE messages
  ADD COLUMN item_type         VARCHAR(20)   NULL,
  ADD COLUMN item_id           VARCHAR(64)   NULL,
  ADD COLUMN item_title        VARCHAR(255)  NULL,
  ADD COLUMN item_image        TEXT          NULL,
  ADD COLUMN item_amount       DECIMAL(15,2) NULL,
  ADD COLUMN item_price_suffix VARCHAR(20)   NULL;
