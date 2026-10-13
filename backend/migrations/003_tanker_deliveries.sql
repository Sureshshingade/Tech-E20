-- Traceable tanker deliveries. This migration preserves all existing fuel records.
CREATE TABLE IF NOT EXISTS tanker_deliveries (
    id BIGINT NOT NULL AUTO_INCREMENT,
    fuel_id INT NOT NULL,
    tank_id INT NULL,
    quantity_litres DECIMAL(12,2) NOT NULL,
    stock_before_litres DECIMAL(12,2) NOT NULL,
    stock_after_litres DECIMAL(12,2) NOT NULL,
    received_at DATETIME NOT NULL,
    supplier_name VARCHAR(120) NULL,
    challan_number VARCHAR(80) NULL,
    notes VARCHAR(500) NULL,
    created_by INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_delivery_fuel_received (fuel_id, received_at),
    KEY idx_delivery_tank_received (tank_id, received_at),
    CONSTRAINT fk_delivery_fuel FOREIGN KEY (fuel_id) REFERENCES fuels(id),
    CONSTRAINT fk_delivery_tank FOREIGN KEY (tank_id) REFERENCES tanks(id),
    CONSTRAINT fk_delivery_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;
