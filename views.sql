-- =====================================================================
-- DATABASE VIEWS: Kolkata City Hospital Management System
-- Minimum 2 required; 3 implemented
-- =====================================================================

DROP VIEW IF EXISTS v_patient_medical_history;
DROP VIEW IF EXISTS v_doctor_workload_metrics;
DROP VIEW IF EXISTS v_billing_financial_summary;

-- VIEW 1: Comprehensive Patient Medical History
-- Denormalizes patient demographics, diagnosis, attending physician, and visit vitals
CREATE VIEW v_patient_medical_history AS
SELECT 
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.gender,
    p.blood_group,
    p.phone AS patient_phone,
    v.visit_id,
    v.visit_date,
    v.symptoms,
    v.blood_pressure,
    v.pulse_rate,
    v.temperature_f,
    d.first_name || ' ' || d.last_name AS doctor_name,
    dept.dept_name,
    diag.condition_name,
    diag.severity,
    diag.icd_code
FROM PATIENT p
JOIN VISIT v ON p.patient_id = v.patient_id
JOIN DOCTOR d ON v.doctor_id = d.doctor_id
JOIN DEPARTMENT dept ON d.dept_id = dept.dept_id
LEFT JOIN DIAGNOSIS diag ON v.visit_id = diag.visit_id;

-- VIEW 2: Doctor Workload and Performance Metrics
-- Aggregates consultation volume, distinct patients treated, and department affiliation
CREATE VIEW v_doctor_workload_metrics AS
SELECT 
    d.doctor_id,
    d.first_name || ' ' || d.last_name AS doctor_name,
    dept.dept_name,
    d.specialization,
    d.consultation_fee,
    COUNT(a.appointment_id) AS total_appointments,
    COUNT(CASE WHEN a.status = 'Completed' THEN 1 END) AS completed_appointments,
    COUNT(DISTINCT a.patient_id) AS unique_patients_treated,
    COALESCE(SUM(CASE WHEN b.payment_status = 'Paid' THEN b.consultation_fee ELSE 0 END), 0) AS realized_consultation_revenue
FROM DOCTOR d
JOIN DEPARTMENT dept ON d.dept_id = dept.dept_id
LEFT JOIN APPOINTMENT a ON d.doctor_id = a.doctor_id
LEFT JOIN VISIT v ON a.appointment_id = v.appointment_id
LEFT JOIN BILL b ON v.visit_id = b.visit_id
GROUP BY d.doctor_id, d.first_name, d.last_name, dept.dept_name, d.specialization, d.consultation_fee;

-- VIEW 3: Billing and Collections Summary View
-- Summary of bills, patient contact, payments made, and outstanding balances
CREATE VIEW v_billing_financial_summary AS
SELECT 
    b.bill_id,
    b.bill_date,
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.phone AS patient_phone,
    b.consultation_fee,
    b.lab_charges,
    b.pharmacy_charges,
    b.total_amount,
    b.discount_amount,
    b.net_payable,
    COALESCE(SUM(pay.amount_paid), 0) AS total_paid,
    (b.net_payable - COALESCE(SUM(pay.amount_paid), 0)) AS balance_due,
    b.payment_status
FROM BILL b
JOIN PATIENT p ON b.patient_id = p.patient_id
LEFT JOIN PAYMENT pay ON b.bill_id = pay.bill_id
GROUP BY b.bill_id, b.bill_date, p.patient_id, p.first_name, p.last_name, p.phone,
         b.consultation_fee, b.lab_charges, b.pharmacy_charges, b.total_amount, b.discount_amount, b.net_payable, b.payment_status;
