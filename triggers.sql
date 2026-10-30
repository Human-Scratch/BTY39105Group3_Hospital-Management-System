-- =====================================================================
-- DATABASE TRIGGERS: Kolkata City Hospital Management System
-- Minimum 2 Triggers Required
-- Included:
-- 1. trg_prevent_duplicate_appointment (MANDATORY ADVANCED REQUIREMENT)
--    Prevents booking conflicting appointment slots for the same doctor.
-- 2. trg_update_bill_on_payment
--    Automatically reconciles and updates bill payment_status when payment is recorded.
-- 3. trg_deduct_pharmacy_stock
--    Automatically reduces medicine inventory upon prescription item issuance.
-- =====================================================================

-- ---------------------------------------------------------------------
-- TRIGGER 1: Prevent Duplicate Appointment Slots for the Same Doctor
-- (Mandatory Advanced DBMS Component from Group 3 specification)
-- ---------------------------------------------------------------------

-- SQLite Syntax:
DROP TRIGGER IF EXISTS trg_prevent_duplicate_appointment_sqlite;
CREATE TRIGGER trg_prevent_duplicate_appointment_sqlite
BEFORE INSERT ON APPOINTMENT
FOR EACH ROW
WHEN EXISTS (
    SELECT 1 FROM APPOINTMENT
    WHERE doctor_id = NEW.doctor_id
      AND appointment_date = NEW.appointment_date
      AND time_slot = NEW.time_slot
      AND status != 'Cancelled'
)
BEGIN
    SELECT RAISE(ABORT, 'CONFLICT: The selected doctor already has a confirmed appointment scheduled for this date and time slot.');
END;

-- MySQL / MariaDB Syntax:
/*
DELIMITER $$
DROP TRIGGER IF EXISTS trg_prevent_duplicate_appointment_mysql$$
CREATE TRIGGER trg_prevent_duplicate_appointment_mysql
BEFORE INSERT ON APPOINTMENT
FOR EACH ROW
BEGIN
    DECLARE v_slot_count INT;
    SELECT COUNT(*) INTO v_slot_count
    FROM APPOINTMENT
    WHERE doctor_id = NEW.doctor_id
      AND appointment_date = NEW.appointment_date
      AND time_slot = NEW.time_slot
      AND status != 'Cancelled';
      
    IF v_slot_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'CONFLICT: Doctor is already booked for this specific appointment slot.';
    END IF;
END$$
DELIMITER ;
*/

-- ---------------------------------------------------------------------
-- TRIGGER 2: Auto-Update Bill Status Upon Payment
-- ---------------------------------------------------------------------

-- SQLite Syntax:
DROP TRIGGER IF EXISTS trg_update_bill_on_payment_sqlite;
CREATE TRIGGER trg_update_bill_on_payment_sqlite
AFTER INSERT ON PAYMENT
FOR EACH ROW
BEGIN
    UPDATE BILL
    SET payment_status = CASE 
        WHEN (
            SELECT COALESCE(SUM(amount_paid), 0) 
            FROM PAYMENT 
            WHERE bill_id = NEW.bill_id
        ) >= net_payable THEN 'Paid'
        ELSE 'Partially Paid'
    END
    WHERE bill_id = NEW.bill_id;
END;

-- MySQL / MariaDB Syntax:
/*
DELIMITER $$
DROP TRIGGER IF EXISTS trg_update_bill_on_payment_mysql$$
CREATE TRIGGER trg_update_bill_on_payment_mysql
AFTER INSERT ON PAYMENT
FOR EACH ROW
BEGIN
    DECLARE v_total_paid DECIMAL(10,2);
    DECLARE v_net_due DECIMAL(10,2);
    
    SELECT COALESCE(SUM(amount_paid), 0) INTO v_total_paid
    FROM PAYMENT
    WHERE bill_id = NEW.bill_id;
    
    SELECT net_payable INTO v_net_due
    FROM BILL
    WHERE bill_id = NEW.bill_id;
    
    IF v_total_paid >= v_net_due THEN
        UPDATE BILL SET payment_status = 'Paid' WHERE bill_id = NEW.bill_id;
    ELSEIF v_total_paid > 0 THEN
        UPDATE BILL SET payment_status = 'Partially Paid' WHERE bill_id = NEW.bill_id;
    END IF;
END$$
DELIMITER ;
*/

-- ---------------------------------------------------------------------
-- TRIGGER 3: Auto-Deduct Medicine Stock and Validate Inventory
-- ---------------------------------------------------------------------

-- SQLite Syntax:
DROP TRIGGER IF EXISTS trg_deduct_pharmacy_stock_sqlite;
CREATE TRIGGER trg_deduct_pharmacy_stock_sqlite
BEFORE INSERT ON PRESCRIPTION_DETAIL
FOR EACH ROW
BEGIN
    -- Check if sufficient stock exists
    SELECT CASE
        WHEN (SELECT stock_quantity FROM MEDICINE WHERE medicine_id = NEW.medicine_id) < NEW.quantity
        THEN RAISE(ABORT, 'INSUFFICIENT STOCK: Cannot prescribe requested quantity exceeding current pharmacy inventory.')
    END;
    
    -- Deduct stock
    UPDATE MEDICINE
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE medicine_id = NEW.medicine_id;
END;
