-- One-row station settings, retained separately from user accounts.
CREATE TABLE IF NOT EXISTS station_settings (
    id TINYINT NOT NULL PRIMARY KEY,
    station_name VARCHAR(120) NOT NULL DEFAULT 'My Petrol Pump',
    updated_by INT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_station_settings_user FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;
INSERT IGNORE INTO station_settings (id, station_name) VALUES (1, 'My Petrol Pump');
