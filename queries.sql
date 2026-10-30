-- =====================================================================
-- DATABASE QUERIES: Kolkata City Hospital Management System
-- Satisfies All Academic Evaluation Criteria:
-- - Basic SELECT queries (Min 10)
-- - Aggregate/GROUP BY queries (Min 5)
-- - JOIN queries (Min 5)
-- - Subqueries (Min 3)
-- - Correlated Subqueries (Min 2)
-- - Dashboard / Report queries (Min 5)
-- =====================================================================

-- =====================================================================
-- SECTION 1: BASIC SELECT QUERIES (10 Queries)
-- =====================================================================

-- Q1.1: List all active clinical departments located in Block A
SELECT dept_id, dept_name, head_of_dept, location_block, phone_extension 
FROM DEPARTMENT 
WHERE location_block LIKE '%Block A%'
ORDER BY dept_id ASC;

-- Q1.2: Retrieve all available doctors with consultation fee under Rs. 1000
SELECT doctor_id, first_name, last_name, specialization, consultation_fee, room_no 
FROM DOCTOR 
WHERE is_available = 1 AND consultation_fee <= 1000.00
ORDER BY consultation_fee ASC;

-- Q1.3: Find all female patients registered with O+ blood group
SELECT patient_id, first_name, last_name, date_of_birth, phone, address 
FROM PATIENT 
WHERE gender = 'Female' AND blood_group = 'O+'
ORDER BY last_name ASC;

-- Q1.4: List all scheduled appointments booked for future dates
SELECT appointment_id, patient_id, doctor_id, appointment_date, time_slot, reason 
FROM APPOINTMENT 
WHERE status = 'Scheduled'
ORDER BY appointment_date ASC, time_slot ASC;

-- Q1.5: Retrieve high-cost medicines with unit price exceeding Rs. 20
SELECT medicine_id, medicine_name, generic_name, category, unit_price, stock_quantity 
FROM MEDICINE 
WHERE unit_price >= 20.00
ORDER BY unit_price DESC;

-- Q1.6: Display all pathology lab tests requiring blood samples
SELECT test_id, test_name, category, standard_fee, turnaround_hours, sample_type 
FROM LAB_TEST 
WHERE sample_type LIKE '%Blood%'
ORDER BY standard_fee ASC;

-- Q1.7: List all unpaid or partially paid hospital bills
SELECT bill_id, patient_id, bill_date, total_amount, discount_amount, net_payable, payment_status 
FROM BILL 
WHERE payment_status IN ('Unpaid', 'Partially Paid')
ORDER BY bill_date DESC;

-- Q1.8: Search for patients residing in Salt Lake or New Town, Kolkata
SELECT patient_id, first_name, last_name, phone, address 
FROM PATIENT 
WHERE address LIKE '%Salt Lake%' OR address LIKE '%New Town%'
ORDER BY patient_id ASC;

-- Q1.9: Retrieve vital measurements showing elevated systolic blood pressure (>140 mmHg)
SELECT visit_id, patient_id, doctor_id, visit_date, blood_pressure, pulse_rate, temperature_f 
FROM VISIT 
WHERE CAST(SUBSTR(blood_pressure, 1, INSTR(blood_pressure, '/') - 1) AS INTEGER) >= 140
ORDER BY visit_date DESC;

-- Q1.10: Find all transactions settled via UPI digital payment modes
SELECT payment_id, bill_id, payment_date, amount_paid, payment_mode, transaction_ref 
FROM PAYMENT 
WHERE payment_mode = 'UPI'
ORDER BY payment_date DESC;


-- =====================================================================
-- SECTION 2: AGGREGATE & GROUP BY QUERIES (5 Queries)
-- =====================================================================

-- Q2.1: Count number of doctors and average consultation fee per department
SELECT 
    dept.dept_name,
    COUNT(d.doctor_id) AS total_doctors,
    ROUND(AVG(d.consultation_fee), 2) AS avg_fee,
    MIN(d.consultation_fee) AS min_fee,
    MAX(d.consultation_fee) AS max_fee
FROM DEPARTMENT dept
LEFT JOIN DOCTOR d ON dept.dept_id = d.dept_id
GROUP BY dept.dept_id, dept.dept_name
HAVING COUNT(d.doctor_id) > 0
ORDER BY total_doctors DESC;

-- Q2.2: Distribution of registered patients by blood group
SELECT 
    blood_group,
    COUNT(*) AS patient_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM PATIENT), 2) AS percentage
FROM PATIENT
GROUP BY blood_group
ORDER BY patient_count DESC;

-- Q2.3: Total billing volume, discounts given, and net revenue by payment status
SELECT 
    payment_status,
    COUNT(*) AS total_bills,
    SUM(total_amount) AS gross_billed,
    SUM(discount_amount) AS total_discounts,
    SUM(net_payable) AS net_revenue
FROM BILL
GROUP BY payment_status;

-- Q2.4: Lab test demand analysis: number of times ordered and total test revenue
SELECT 
    lt.test_id,
    lt.test_name,
    lt.category,
    COUNT(lto.order_id) AS orders_count,
    SUM(lt.standard_fee) AS total_generated_fees
FROM LAB_TEST lt
JOIN LAB_TEST_ORDER lto ON lt.test_id = lto.test_id
GROUP BY lt.test_id, lt.test_name, lt.category
ORDER BY orders_count DESC;

-- Q2.5: Pharmacy inventory valuation and total units in stock per category
SELECT 
    category,
    COUNT(*) AS medicine_count,
    SUM(stock_quantity) AS total_stock_units,
    ROUND(SUM(unit_price * stock_quantity), 2) AS total_inventory_value
FROM MEDICINE
GROUP BY category
ORDER BY total_inventory_value DESC;


-- =====================================================================
-- SECTION 3: MULTI-TABLE JOIN QUERIES (5 Queries)
-- =====================================================================

-- Q3.1: Complete Appointment Details (Patient, Doctor, Department)
SELECT 
    a.appointment_id,
    a.appointment_date,
    a.time_slot,
    a.status,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.phone AS patient_phone,
    d.first_name || ' ' || d.last_name AS doctor_name,
    d.room_no,
    dept.dept_name
FROM APPOINTMENT a
INNER JOIN PATIENT p ON a.patient_id = p.patient_id
INNER JOIN DOCTOR d ON a.doctor_id = d.doctor_id
INNER JOIN DEPARTMENT dept ON d.dept_id = dept.dept_id
ORDER BY a.appointment_date DESC, a.time_slot ASC;

-- Q3.2: Full Clinical Diagnosis & Attending Physician Record
SELECT 
    v.visit_id,
    v.visit_date,
    p.first_name || ' ' || p.last_name AS patient_name,
    d.first_name || ' ' || d.last_name AS doctor_name,
    diag.icd_code,
    diag.condition_name,
    diag.severity,
    v.symptoms
FROM VISIT v
INNER JOIN PATIENT p ON v.patient_id = p.patient_id
INNER JOIN DOCTOR d ON v.doctor_id = d.doctor_id
INNER JOIN DIAGNOSIS diag ON v.visit_id = diag.visit_id
ORDER BY v.visit_date DESC;

-- Q3.3: Itemized Prescription Details with Medicine Generic Names and Total Cost
SELECT 
    pr.prescription_id,
    pr.prescription_date,
    p.first_name || ' ' || p.last_name AS patient_name,
    d.first_name || ' ' || d.last_name AS doctor_name,
    m.medicine_name,
    m.generic_name,
    pd.dosage,
    pd.frequency,
    pd.duration_days,
    pd.quantity,
    m.unit_price,
    ROUND(pd.quantity * m.unit_price, 2) AS line_total
FROM PRESCRIPTION pr
INNER JOIN PATIENT p ON pr.patient_id = p.patient_id
INNER JOIN DOCTOR d ON pr.doctor_id = d.doctor_id
INNER JOIN PRESCRIPTION_DETAIL pd ON pr.prescription_id = pd.prescription_id
INNER JOIN MEDICINE m ON pd.medicine_id = m.medicine_id
ORDER BY pr.prescription_id ASC, m.medicine_name ASC;

-- Q3.4: Comprehensive Lab Order Tracking with Patient & Doctor Details
SELECT 
    lto.order_id,
    lto.order_date,
    p.first_name || ' ' || p.last_name AS patient_name,
    lt.test_name,
    lt.category,
    lt.standard_fee,
    lto.status,
    lto.result_value,
    lto.normal_range
FROM LAB_TEST_ORDER lto
INNER JOIN PATIENT p ON lto.patient_id = p.patient_id
INNER JOIN LAB_TEST lt ON lto.test_id = lt.test_id
INNER JOIN VISIT v ON lto.visit_id = v.visit_id
ORDER BY lto.order_date DESC;

-- Q3.5: Billing and Payment Settlement Reconciliation
SELECT 
    b.bill_id,
    b.bill_date,
    p.first_name || ' ' || p.last_name AS patient_name,
    b.net_payable,
    COALESCE(pay.amount_paid, 0) AS amount_paid,
    pay.payment_mode,
    pay.transaction_ref,
    pay.payment_date,
    b.payment_status
FROM BILL b
INNER JOIN PATIENT p ON b.patient_id = p.patient_id
LEFT JOIN PAYMENT pay ON b.bill_id = pay.bill_id
ORDER BY b.bill_id ASC;


-- =====================================================================
-- SECTION 4: SUBQUERIES (3 Queries)
-- =====================================================================

-- Q4.1: Find patients who have never cancelled an appointment
SELECT patient_id, first_name, last_name, phone, email
FROM PATIENT
WHERE patient_id IN (
    SELECT DISTINCT patient_id 
    FROM APPOINTMENT 
    WHERE status != 'Cancelled'
)
AND patient_id NOT IN (
    SELECT DISTINCT patient_id 
    FROM APPOINTMENT 
    WHERE status = 'Cancelled'
);

-- Q4.2: List medicines whose unit price is strictly above the average medicine price
SELECT medicine_id, medicine_name, generic_name, category, unit_price
FROM MEDICINE
WHERE unit_price > (
    SELECT AVG(unit_price) 
    FROM MEDICINE
)
ORDER BY unit_price DESC;

-- Q4.3: Find doctors who have handled visits for patients with 'Severe' or 'Critical' diagnoses
SELECT doctor_id, first_name, last_name, specialization, room_no
FROM DOCTOR
WHERE doctor_id IN (
    SELECT DISTINCT v.doctor_id
    FROM VISIT v
    JOIN DIAGNOSIS d ON v.visit_id = d.visit_id
    WHERE d.severity IN ('Severe', 'Critical')
);


-- =====================================================================
-- SECTION 5: CORRELATED SUBQUERIES (2 Queries)
-- =====================================================================

-- Q5.1: Find doctors whose consultation fee is higher than the average fee of their OWN department
SELECT d1.doctor_id, d1.first_name, d1.last_name, d1.dept_id, d1.specialization, d1.consultation_fee
FROM DOCTOR d1
WHERE d1.consultation_fee > (
    SELECT AVG(d2.consultation_fee)
    FROM DOCTOR d2
    WHERE d2.dept_id = d1.dept_id
)
ORDER BY d1.dept_id, d1.consultation_fee DESC;

-- Q5.2: Find patients whose total hospital billing exceeds the average patient billing
SELECT p.patient_id, p.first_name, p.last_name, p.phone
FROM PATIENT p
WHERE (
    SELECT SUM(b.net_payable)
    FROM BILL b
    WHERE b.patient_id = p.patient_id
) > (
    SELECT AVG(total_patient_bill)
    FROM (
        SELECT SUM(net_payable) AS total_patient_bill
        FROM BILL
        GROUP BY patient_id
    )
);


-- =====================================================================
-- SECTION 6: DASHBOARD / REPORT QUERIES (5 Queries)
-- =====================================================================

-- Q6.1: Executive KPI Summary Card (Total Patients, Doctors, Appointments, Revenue)
SELECT 
    (SELECT COUNT(*) FROM PATIENT) AS total_patients,
    (SELECT COUNT(*) FROM DOCTOR WHERE is_available = 1) AS active_doctors,
    (SELECT COUNT(*) FROM APPOINTMENT WHERE status = 'Completed') AS completed_appointments,
    (SELECT COUNT(*) FROM APPOINTMENT WHERE status = 'Scheduled') AS pending_appointments,
    (SELECT COALESCE(SUM(amount_paid), 0) FROM PAYMENT) AS total_revenue_collected,
    (SELECT COALESCE(SUM(net_payable), 0) FROM BILL WHERE payment_status != 'Paid') AS outstanding_dues;

-- Q6.2: Department-wise Patient Footfall and Revenue Breakdown
SELECT 
    dept.dept_name,
    COUNT(DISTINCT v.visit_id) AS total_visits,
    COUNT(DISTINCT a.appointment_id) AS total_bookings,
    COALESCE(SUM(b.consultation_fee), 0) AS total_consultation_revenue,
    COALESCE(SUM(b.lab_charges), 0) AS total_lab_revenue,
    COALESCE(SUM(b.net_payable), 0) AS department_total_billed
FROM DEPARTMENT dept
LEFT JOIN DOCTOR d ON dept.dept_id = d.dept_id
LEFT JOIN VISIT v ON d.doctor_id = v.doctor_id
LEFT JOIN APPOINTMENT a ON d.doctor_id = a.doctor_id
LEFT JOIN BILL b ON v.visit_id = b.visit_id
GROUP BY dept.dept_id, dept.dept_name
ORDER BY department_total_billed DESC;

-- Q6.3: Top 5 Prescribed Medications in the Hospital
SELECT 
    m.medicine_name,
    m.generic_name,
    m.category,
    SUM(pd.quantity) AS total_units_prescribed,
    COUNT(DISTINCT pd.prescription_id) AS prescription_count,
    ROUND(SUM(pd.quantity * m.unit_price), 2) AS estimated_sales_value
FROM MEDICINE m
JOIN PRESCRIPTION_DETAIL pd ON m.medicine_id = pd.medicine_id
GROUP BY m.medicine_id, m.medicine_name, m.generic_name, m.category
ORDER BY total_units_prescribed DESC
LIMIT 5;

-- Q6.4: Daily Patient Visit and Collection Trend (October 2026)
SELECT 
    DATE(v.visit_date) AS consultation_date,
    COUNT(DISTINCT v.visit_id) AS patient_visits,
    COUNT(DISTINCT v.doctor_id) AS doctors_on_duty,
    COALESCE(SUM(p.amount_paid), 0) AS daily_collections
FROM VISIT v
LEFT JOIN BILL b ON v.visit_id = b.visit_id
LEFT JOIN PAYMENT p ON b.bill_id = p.bill_id AND DATE(p.payment_date) = DATE(v.visit_date)
GROUP BY DATE(v.visit_date)
ORDER BY consultation_date DESC;

-- Q6.5: Diagnostic Laboratory Utilization and Category Revenue
SELECT 
    lt.category AS lab_discipline,
    COUNT(lto.order_id) AS tests_conducted,
    COUNT(CASE WHEN lto.status = 'Completed' THEN 1 END) AS tests_completed,
    ROUND(AVG(lt.turnaround_hours), 1) AS avg_turnaround_hrs,
    SUM(lt.standard_fee) AS total_lab_earnings
FROM LAB_TEST lt
JOIN LAB_TEST_ORDER lto ON lt.test_id = lto.test_id
GROUP BY lt.category
ORDER BY total_lab_earnings DESC;
