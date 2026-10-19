-- Add the city used for read-only live fuel-rate display.
ALTER TABLE station_settings
    ADD COLUMN city VARCHAR(100) NOT NULL DEFAULT 'Mumbai' AFTER station_name;
