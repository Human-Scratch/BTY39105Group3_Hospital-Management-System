-- =====================================================================
-- STORED PROCEDURES, FUNCTIONS & TRANSACTION DEMONSTRATION (MySQL 8.0+)
-- Kolkata City Hospital & Medical Research Centre (KCHMRC)
-- =====================================================================

USE kolkata_hospital_db;

DELIMITER $$

-- ---------------------------------------------------------------------
-- PROCEDURE 1: sp_book_appointment
-- Safely books an appointment with validation and transaction management
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_book_appointment$$
CREATE PROCEDURE sp_book_appointment(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_appointment_date DATE,
    IN p_time_slot VARCHAR(20),
    IN p_reason TEXT,
    OUT p_appointment_id INT,
    OUT p_status_message VARCHAR(255)
)
BEGIN
    DECLARE v_count INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_message = 'ERROR: Database transaction failed during appointment booking.';
    END;

    START TRANSACTION;

    -- Step 1: Verify doctor slot availability
    SELECT COUNT(*) INTO v_count
    FROM APPOINTMENT
    WHERE doctor_id = p_doctor_id 
      AND appointment_date = p_appointment_date 
      AND time_slot = p_time_slot 
      AND status != 'Cancelled';

    IF v_count > 0 THEN
        SET p_status_message = 'FAILED: Doctor slot already reserved.';
        ROLLBACK;
    ELSE
        -- Step 2: Insert appointment record
        INSERT INTO APPOINTMENT (patient_id, doctor_id, appointment_date, time_slot, status, reason)
        VALUES (p_patient_id, p_doctor_id, p_appointment_date, p_time_slot, 'Scheduled', p_reason);
        
        SET p_appointment_id = LAST_INSERT_ID();
        SET p_status_message = 'SUCCESS: Appointment scheduled successfully.';
        COMMIT;
    END IF;
END$$

-- ---------------------------------------------------------------------
-- PROCEDURE 2: sp_generate_final_bill
-- Aggregates consultation, pathology tests, and pharmacy prescription
-- into a unified patient invoice within an ACID transaction
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_generate_final_bill$$
CREATE PROCEDURE sp_generate_final_bill(
    IN p_visit_id INT,
    IN p_discount_percent DECIMAL(5,2),
    OUT p_bill_id INT,
    OUT p_net_payable DECIMAL(10,2)
)
BEGIN
    DECLARE v_patient_id INT;
    DECLARE v_doctor_id INT;
    DECLARE v_consult_fee DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_lab_total DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_pharmacy_total DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_subtotal DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_discount DECIMAL(10,2) DEFAULT 0.00;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 1. Fetch patient and doctor from visit
    SELECT patient_id, doctor_id INTO v_patient_id, v_doctor_id
    FROM VISIT WHERE visit_id = p_visit_id;

    -- 2. Fetch doctor consultation fee
    SELECT consultation_fee INTO v_consult_fee
    FROM DOCTOR WHERE doctor_id = v_doctor_id;

    -- 3. Sum lab test fees ordered for this visit
    SELECT COALESCE(SUM(lt.standard_fee), 0.00) INTO v_lab_total
    FROM LAB_TEST_ORDER lto
    JOIN LAB_TEST lt ON lto.test_id = lt.test_id
    WHERE lto.visit_id = p_visit_id;

    -- 4. Sum pharmacy prescription items for this visit
    SELECT COALESCE(SUM(pd.quantity * m.unit_price), 0.00) INTO v_pharmacy_total
    FROM PRESCRIPTION pr
    JOIN PRESCRIPTION_DETAIL pd ON pr.prescription_id = pd.prescription_id
    JOIN MEDICINE m ON pd.medicine_id = m.medicine_id
    WHERE pr.visit_id = p_visit_id;

    -- 5. Calculate totals
    SET v_subtotal = v_consult_fee + v_lab_total + v_pharmacy_total;
    SET v_discount = ROUND(v_subtotal * (p_discount_percent / 100.0), 2);
    SET p_net_payable = v_subtotal - v_discount;

    -- 6. Insert Bill Record
    INSERT INTO BILL (
        patient_id, visit_id, bill_date,
        consultation_fee, lab_charges, pharmacy_charges,
        total_amount, discount_amount, net_payable, payment_status
    ) VALUES (
        v_patient_id, p_visit_id, CURDATE(),
        v_consult_fee, v_lab_total, v_pharmacy_total,
        v_subtotal, v_discount, p_net_payable, 'Unpaid'
    );

    SET p_bill_id = LAST_INSERT_ID();
    COMMIT;
END$$

-- ---------------------------------------------------------------------
-- FUNCTION 1: fn_calculate_patient_balance
-- Calculates cumulative outstanding balance due across all bills for a patient
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_calculate_patient_balance$$
CREATE FUNCTION fn_calculate_patient_balance(p_patient_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total_billed DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_total_paid DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_balance DECIMAL(10,2) DEFAULT 0.00;

    -- Total net payable billed to patient
    SELECT COALESCE(SUM(net_payable), 0.00) INTO v_total_billed
    FROM BILL
    WHERE patient_id = p_patient_id;

    -- Total payments received from patient
    SELECT COALESCE(SUM(p.amount_paid), 0.00) INTO v_total_paid
    FROM PAYMENT p
    JOIN BILL b ON p.bill_id = b.bill_id
    WHERE b.patient_id = p_patient_id;

    SET v_balance = v_total_billed - v_total_paid;
    RETURN v_balance;
END$$

DELIMITER ;

-- =====================================================================
-- SECTION 3: TRANSACTION DEMONSTRATION (MySQL)
-- Atomic Consultation Checkout, Invoicing and Instant UPI Payment
-- Demonstrates ACID properties: Atomicity, Consistency, Isolation, Durability
-- =====================================================================

START TRANSACTION;

-- Step A: Insert Bill for Patient 20, Visit 20
INSERT INTO BILL (
    bill_id, patient_id, visit_id, bill_date,
    consultation_fee, lab_charges, pharmacy_charges,
    total_amount, discount_amount, net_payable, payment_status
) VALUES (
    21, 20, 20, CURDATE(),
    750.00, 730.00, 383.50,
    1863.50, 63.50, 1800.00, 'Unpaid'
);

-- Step B: Insert Payment Record for Bill 21
INSERT INTO PAYMENT (
    payment_id, bill_id, payment_date,
    amount_paid, payment_mode, transaction_ref, remarks
) VALUES (
    21, 21, NOW(),
    1800.00, 'UPI', 'UPI-KCH-DEMO-TRANS-01', 'Complete settlement via PhonePe UPI'
);

-- Step C: Trigger trg_update_bill_on_payment automatically sets status to 'Paid'
COMMIT;

-- Verify Transaction Success
SELECT b.bill_id, b.patient_id, b.net_payable, b.payment_status, p.amount_paid, p.transaction_ref
FROM BILL b
JOIN PAYMENT p ON b.bill_id = p.bill_id
WHERE b.bill_id = 21;
