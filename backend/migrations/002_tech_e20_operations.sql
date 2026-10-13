-- Tech-E20 operational schema. Additive only: existing users and fuels are preserved.
CREATE TABLE IF NOT EXISTS employee_profiles (
  user_id INT NOT NULL PRIMARY KEY,
  phone VARCHAR(30) NULL, joining_date DATE NULL, default_shift VARCHAR(30) NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_employee_profile_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS shift_templates (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50) NOT NULL UNIQUE,
  starts_at TIME NOT NULL, ends_at TIME NOT NULL, is_active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;
INSERT IGNORE INTO shift_templates (name, starts_at, ends_at) VALUES ('Morning','06:00:00','14:00:00'),('Evening','14:00:00','22:00:00');

CREATE TABLE IF NOT EXISTS shifts (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, shift_date DATE NOT NULL, template_id INT NOT NULL,
  manager_user_id INT NULL, status ENUM('SCHEDULED','OPEN','AWAITING_RECONCILIATION','RECONCILED','CLOSED','VOID') NOT NULL DEFAULT 'SCHEDULED',
  notes VARCHAR(1000) NULL, opened_at DATETIME NULL, closed_at DATETIME NULL, created_by INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_shift_date_template (shift_date, template_id), KEY idx_shifts_date_status (shift_date,status),
  CONSTRAINT fk_shift_template FOREIGN KEY (template_id) REFERENCES shift_templates(id),
  CONSTRAINT fk_shift_manager FOREIGN KEY (manager_user_id) REFERENCES users(id), CONSTRAINT fk_shift_creator FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS shift_assignments (
  shift_id BIGINT NOT NULL, user_id INT NOT NULL, assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (shift_id,user_id), CONSTRAINT fk_assignment_shift FOREIGN KEY (shift_id) REFERENCES shifts(id),
  CONSTRAINT fk_assignment_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS attendance (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, user_id INT NOT NULL, attendance_date DATE NOT NULL, template_id INT NOT NULL,
  status ENUM('PRESENT','ABSENT','LEAVE') NOT NULL, recorded_by INT NOT NULL, correction_reason VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_attendance_person_shift (user_id,attendance_date,template_id), KEY idx_attendance_date (attendance_date),
  CONSTRAINT fk_attendance_user FOREIGN KEY (user_id) REFERENCES users(id), CONSTRAINT fk_attendance_template FOREIGN KEY (template_id) REFERENCES shift_templates(id), CONSTRAINT fk_attendance_recorder FOREIGN KEY (recorded_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tanks (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(40) NOT NULL UNIQUE, fuel_id INT NOT NULL,
  capacity_litres DECIMAL(12,2) NOT NULL, is_active BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_tank_fuel FOREIGN KEY (fuel_id) REFERENCES fuels(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS tank_calibration_points (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, tank_id INT NOT NULL, height_mm DECIMAL(10,2) NOT NULL, volume_litres DECIMAL(12,2) NOT NULL,
  UNIQUE KEY uq_calibration_point (tank_id,height_mm), CONSTRAINT fk_calibration_tank FOREIGN KEY (tank_id) REFERENCES tanks(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS tank_readings (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, tank_id INT NOT NULL, measured_at DATETIME NOT NULL, dip_mm DECIMAL(10,2) NOT NULL,
  volume_litres DECIMAL(12,2) NOT NULL, recorded_by INT NOT NULL, notes VARCHAR(500) NULL, is_void BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, KEY idx_tank_readings_tank_date (tank_id,measured_at),
  CONSTRAINT fk_reading_tank FOREIGN KEY (tank_id) REFERENCES tanks(id), CONSTRAINT fk_reading_user FOREIGN KEY (recorded_by) REFERENCES users(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS inventory_transactions (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, tank_id INT NULL, fuel_id INT NOT NULL, transaction_type ENUM('DELIVERY','ADJUSTMENT','SALE','VOID') NOT NULL,
  quantity_litres DECIMAL(12,2) NOT NULL, reference_type VARCHAR(50) NULL, reference_id BIGINT NULL, reason VARCHAR(500) NULL, created_by INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, KEY idx_inventory_fuel_date (fuel_id,created_at),
  CONSTRAINT fk_inventory_tank FOREIGN KEY (tank_id) REFERENCES tanks(id), CONSTRAINT fk_inventory_fuel FOREIGN KEY (fuel_id) REFERENCES fuels(id), CONSTRAINT fk_inventory_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dispensers (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(40) NOT NULL UNIQUE, is_active BOOLEAN NOT NULL DEFAULT TRUE) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS nozzles (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(40) NOT NULL UNIQUE, dispenser_id INT NOT NULL, fuel_id INT NOT NULL, is_active BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_nozzle_dispenser FOREIGN KEY (dispenser_id) REFERENCES dispensers(id), CONSTRAINT fk_nozzle_fuel FOREIGN KEY (fuel_id) REFERENCES fuels(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS nozzle_readings (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, shift_id BIGINT NOT NULL, nozzle_id INT NOT NULL, employee_user_id INT NULL,
  opening_totalizer DECIMAL(14,3) NOT NULL, closing_totalizer DECIMAL(14,3) NULL, rate_per_litre DECIMAL(10,2) NOT NULL,
  litres_sold DECIMAL(14,3) NULL, expected_sales DECIMAL(14,2) NULL, status ENUM('OPEN','CLOSED','FLAGGED','VOID') NOT NULL DEFAULT 'OPEN',
  recorded_by INT NOT NULL, correction_reason VARCHAR(500) NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_nozzle_shift (shift_id,nozzle_id), CONSTRAINT fk_nozzle_reading_shift FOREIGN KEY (shift_id) REFERENCES shifts(id), CONSTRAINT fk_nozzle_reading_nozzle FOREIGN KEY (nozzle_id) REFERENCES nozzles(id),
  CONSTRAINT fk_nozzle_reading_employee FOREIGN KEY (employee_user_id) REFERENCES users(id), CONSTRAINT fk_nozzle_reading_user FOREIGN KEY (recorded_by) REFERENCES users(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS reconciliations (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, shift_id BIGINT NOT NULL UNIQUE, expected_cash DECIMAL(14,2) NOT NULL DEFAULT 0, expected_upi DECIMAL(14,2) NOT NULL DEFAULT 0, expected_card DECIMAL(14,2) NOT NULL DEFAULT 0,
  actual_cash DECIMAL(14,2) NOT NULL DEFAULT 0, actual_upi DECIMAL(14,2) NOT NULL DEFAULT 0, actual_card DECIMAL(14,2) NOT NULL DEFAULT 0, status ENUM('DRAFT','SUBMITTED','REVIEWED') NOT NULL DEFAULT 'DRAFT',
  notes VARCHAR(1000) NULL, recorded_by INT NOT NULL, reviewed_by INT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_reconciliation_shift FOREIGN KEY (shift_id) REFERENCES shifts(id), CONSTRAINT fk_reconciliation_recorder FOREIGN KEY (recorded_by) REFERENCES users(id), CONSTRAINT fk_reconciliation_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS discrepancy_notes (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, reconciliation_id BIGINT NOT NULL, employee_user_id INT NOT NULL, explanation TEXT NOT NULL, manager_response TEXT NULL, review_status ENUM('OPEN','ACKNOWLEDGED') NOT NULL DEFAULT 'OPEN', created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, responded_at DATETIME NULL,
 CONSTRAINT fk_note_reconciliation FOREIGN KEY (reconciliation_id) REFERENCES reconciliations(id), CONSTRAINT fk_note_employee FOREIGN KEY (employee_user_id) REFERENCES users(id)
) ENGINE=InnoDB;
