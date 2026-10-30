-- =====================================================================
-- DATABASE TRIGGERS (MySQL 8.0+ DELIMITER Syntax)
-- Kolkata City Hospital & Medical Research Centre (KCHMRC)
-- =====================================================================

USE kolkata_hospital_db;

DELIMITER $$

-- ---------------------------------------------------------------------
-- TRIGGER 1: Prevent Duplicate Appointment Slots for the Same Doctor
-- (Mandatory Advanced DBMS Component from Group 3 specification)
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_prevent_duplicate_appointment$$
CREATE TRIGGER trg_prevent_duplicate_appointment
BEFORE INSERT ON APPOINTMENT
FOR EACH ROW
BEGIN
    DECLARE v_slot_count INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_slot_count
    FROM APPOINTMENT
    WHERE doctor_id = NEW.doctor_id
      AND appointment_date = NEW.appointment_date
      AND time_slot = NEW.time_slot
      AND status != 'Cancelled';
      
    IF v_slot_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'CONFLICT: The selected doctor already has a confirmed appointment scheduled for this date and time slot.';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- TRIGGER 2: Auto-Update Bill Status Upon Payment
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_update_bill_on_payment$$
CREATE TRIGGER trg_update_bill_on_payment
AFTER INSERT ON PAYMENT
FOR EACH ROW
BEGIN
    DECLARE v_total_paid DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_net_due DECIMAL(10,2) DEFAULT 0.00;
    
    SELECT COALESCE(SUM(amount_paid), 0.00) INTO v_total_paid
    FROM PAYMENT
    WHERE bill_id = NEW.bill_id;
    
    SELECT net_payable INTO v_net_due
    FROM BILL
    WHERE bill_id = NEW.bill_id;
    
    IF v_total_paid >= v_net_due THEN
        UPDATE BILL SET payment_status = 'Paid' WHERE bill_id = NEW.bill_id;
    ELSEIF v_total_paid > 0.00 THEN
        UPDATE BILL SET payment_status = 'Partially Paid' WHERE bill_id = NEW.bill_id;
    END IF;
END$$

-- ---------------------------------------------------------------------
-- TRIGGER 3: Auto-Deduct Medicine Stock and Validate Inventory
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_deduct_pharmacy_stock$$
CREATE TRIGGER trg_deduct_pharmacy_stock
BEFORE INSERT ON PRESCRIPTION_DETAIL
FOR EACH ROW
BEGIN
    DECLARE v_current_stock INT DEFAULT 0;
    
    SELECT stock_quantity INTO v_current_stock
    FROM MEDICINE
    WHERE medicine_id = NEW.medicine_id;
    
    IF v_current_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'INSUFFICIENT STOCK: Cannot prescribe requested quantity exceeding current pharmacy inventory.';
    ELSE
        UPDATE MEDICINE
        SET stock_quantity = stock_quantity - NEW.quantity
        WHERE medicine_id = NEW.medicine_id;
    END IF;
END$$

DELIMITER ;
