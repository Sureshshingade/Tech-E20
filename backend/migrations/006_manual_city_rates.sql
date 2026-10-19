-- Owner-maintained city reference rates. They do not alter fuel inventory prices or historical calculations.
ALTER TABLE station_settings
    ADD COLUMN city_petrol_rate DECIMAL(10,2) NULL AFTER city,
    ADD COLUMN city_diesel_rate DECIMAL(10,2) NULL AFTER city_petrol_rate,
    ADD COLUMN city_rate_updated_at DATETIME NULL AFTER city_diesel_rate;
