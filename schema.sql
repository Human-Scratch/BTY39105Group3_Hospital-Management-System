-- =====================================================================
-- DATABASE SCHEMA: Kolkata City Hospital & Medical Research Centre (KCHMRC)
-- Group 3: Hospital Patient and Appointment Management System
-- DBMS Support: Compatible with MySQL / PostgreSQL / SQLite
-- =====================================================================

DROP TABLE IF EXISTS PAYMENT;
DROP TABLE IF EXISTS BILL;
DROP TABLE IF EXISTS LAB_TEST_ORDER;
DROP TABLE IF EXISTS LAB_TEST;
DROP TABLE IF EXISTS PRESCRIPTION_DETAIL;
DROP TABLE IF EXISTS MEDICINE;
DROP TABLE IF EXISTS PRESCRIPTION;
DROP TABLE IF EXISTS DIAGNOSIS;
DROP TABLE IF EXISTS VISIT;
DROP TABLE IF EXISTS APPOINTMENT;
DROP TABLE IF EXISTS USER_ACCOUNT;
DROP TABLE IF EXISTS DOCTOR;
DROP TABLE IF EXISTS DEPARTMENT;
DROP TABLE IF EXISTS PATIENT;

-- 1. DEPARTMENT TABLE
CREATE TABLE DEPARTMENT (
    dept_id INTEGER PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL UNIQUE,
    head_of_dept VARCHAR(100) NOT NULL,
    location_block VARCHAR(50) NOT NULL,
    phone_extension VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. DOCTOR TABLE
CREATE TABLE DOCTOR (
    doctor_id INTEGER PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL UNIQUE,
    specialization VARCHAR(100) NOT NULL,
    dept_id INTEGER NOT NULL,
    qualification VARCHAR(100) NOT NULL,
    consultation_fee DECIMAL(10, 2) NOT NULL CHECK (consultation_fee >= 0),
    room_no VARCHAR(20) NOT NULL,
    is_available BOOLEAN DEFAULT 1,
    FOREIGN KEY (dept_id) REFERENCES DEPARTMENT(dept_id) ON DELETE RESTRICT
);

-- 3. PATIENT TABLE
CREATE TABLE PATIENT (
    patient_id INTEGER PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('Male', 'Female', 'Other')),
    blood_group VARCHAR(5) CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100) UNIQUE,
    address TEXT NOT NULL,
    emergency_contact VARCHAR(20) NOT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. USER_ACCOUNT (Role-based access control: Admin, Manager, Doctor, Staff, Patient)
CREATE TABLE USER_ACCOUNT (
    user_id INTEGER PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('Admin', 'Manager', 'Doctor', 'Staff', 'Patient')),
    linked_doctor_id INTEGER,
    linked_patient_id INTEGER,
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (linked_doctor_id) REFERENCES DOCTOR(doctor_id) ON DELETE SET NULL,
    FOREIGN KEY (linked_patient_id) REFERENCES PATIENT(patient_id) ON DELETE SET NULL
);

-- 5. APPOINTMENT TABLE (Enforcing slot integrity)
CREATE TABLE APPOINTMENT (
    appointment_id INTEGER PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    doctor_id INTEGER NOT NULL,
    appointment_date DATE NOT NULL,
    time_slot VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Completed', 'Cancelled', 'No-Show')),
    reason TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_doctor_slot UNIQUE (doctor_id, appointment_date, time_slot),
    FOREIGN KEY (patient_id) REFERENCES PATIENT(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (doctor_id) REFERENCES DOCTOR(doctor_id) ON DELETE RESTRICT
);

-- 6. VISIT TABLE (Outpatient/Inpatient consultation record)
CREATE TABLE VISIT (
    visit_id INTEGER PRIMARY KEY,
    appointment_id INTEGER UNIQUE,
    patient_id INTEGER NOT NULL,
    doctor_id INTEGER NOT NULL,
    visit_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    symptoms TEXT NOT NULL,
    blood_pressure VARCHAR(20),
    pulse_rate INTEGER CHECK (pulse_rate > 0),
    temperature_f DECIMAL(4, 1),
    weight_kg DECIMAL(5, 2),
    doctor_notes TEXT,
    FOREIGN KEY (appointment_id) REFERENCES APPOINTMENT(appointment_id) ON DELETE SET NULL,
    FOREIGN KEY (patient_id) REFERENCES PATIENT(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (doctor_id) REFERENCES DOCTOR(doctor_id) ON DELETE RESTRICT
);

-- 7. DIAGNOSIS TABLE
CREATE TABLE DIAGNOSIS (
    diagnosis_id INTEGER PRIMARY KEY,
    visit_id INTEGER NOT NULL,
    icd_code VARCHAR(20) NOT NULL,
    condition_name VARCHAR(150) NOT NULL,
    severity VARCHAR(20) CHECK (severity IN ('Mild', 'Moderate', 'Severe', 'Critical')),
    diagnosis_notes TEXT,
    diagnosed_date DATE NOT NULL,
    FOREIGN KEY (visit_id) REFERENCES VISIT(visit_id) ON DELETE CASCADE
);

-- 8. PRESCRIPTION TABLE
CREATE TABLE PRESCRIPTION (
    prescription_id INTEGER PRIMARY KEY,
    visit_id INTEGER NOT NULL,
    doctor_id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    prescription_date DATE NOT NULL,
    advice_notes TEXT,
    FOREIGN KEY (visit_id) REFERENCES VISIT(visit_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES DOCTOR(doctor_id) ON DELETE RESTRICT,
    FOREIGN KEY (patient_id) REFERENCES PATIENT(patient_id) ON DELETE RESTRICT
);

-- 9. MEDICINE TABLE (Hospital Pharmacy Catalog)
CREATE TABLE MEDICINE (
    medicine_id INTEGER PRIMARY KEY,
    medicine_name VARCHAR(100) NOT NULL,
    generic_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    dosage_form VARCHAR(30) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0),
    manufacturer VARCHAR(100) NOT NULL
);

-- 10. PRESCRIPTION_DETAIL TABLE
CREATE TABLE PRESCRIPTION_DETAIL (
    item_id INTEGER PRIMARY KEY,
    prescription_id INTEGER NOT NULL,
    medicine_id INTEGER NOT NULL,
    dosage VARCHAR(50) NOT NULL,
    frequency VARCHAR(50) NOT NULL,
    duration_days INTEGER NOT NULL CHECK (duration_days > 0),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    FOREIGN KEY (prescription_id) REFERENCES PRESCRIPTION(prescription_id) ON DELETE CASCADE,
    FOREIGN KEY (medicine_id) REFERENCES MEDICINE(medicine_id) ON DELETE RESTRICT
);

-- 11. LAB_TEST TABLE (Hospital Pathology/Radiology Catalog)
CREATE TABLE LAB_TEST (
    test_id INTEGER PRIMARY KEY,
    test_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL CHECK (category IN ('Pathology', 'Radiology', 'Biochemistry', 'Microbiology', 'Cardiology')),
    standard_fee DECIMAL(10, 2) NOT NULL CHECK (standard_fee >= 0),
    turnaround_hours INTEGER NOT NULL CHECK (turnaround_hours > 0),
    sample_type VARCHAR(50) NOT NULL
);

-- 12. LAB_TEST_ORDER TABLE
CREATE TABLE LAB_TEST_ORDER (
    order_id INTEGER PRIMARY KEY,
    visit_id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    test_id INTEGER NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Ordered' CHECK (status IN ('Ordered', 'Sample Collected', 'In-Process', 'Completed')),
    result_value TEXT,
    normal_range VARCHAR(100),
    technician_remarks TEXT,
    FOREIGN KEY (visit_id) REFERENCES VISIT(visit_id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES PATIENT(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (test_id) REFERENCES LAB_TEST(test_id) ON DELETE RESTRICT
);

-- 13. BILL TABLE (Financial invoicing)
CREATE TABLE BILL (
    bill_id INTEGER PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    visit_id INTEGER UNIQUE,
    bill_date DATE NOT NULL,
    consultation_fee DECIMAL(10, 2) DEFAULT 0.00,
    lab_charges DECIMAL(10, 2) DEFAULT 0.00,
    pharmacy_charges DECIMAL(10, 2) DEFAULT 0.00,
    total_amount DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
    discount_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (discount_amount >= 0),
    net_payable DECIMAL(10, 2) NOT NULL CHECK (net_payable >= 0),
    payment_status VARCHAR(20) DEFAULT 'Unpaid' CHECK (payment_status IN ('Unpaid', 'Partially Paid', 'Paid')),
    FOREIGN KEY (patient_id) REFERENCES PATIENT(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (visit_id) REFERENCES VISIT(visit_id) ON DELETE SET NULL
);

-- 14. PAYMENT TABLE (Payment transactions)
CREATE TABLE PAYMENT (
    payment_id INTEGER PRIMARY KEY,
    bill_id INTEGER NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount_paid DECIMAL(10, 2) NOT NULL CHECK (amount_paid > 0),
    payment_mode VARCHAR(30) NOT NULL CHECK (payment_mode IN ('Cash', 'UPI', 'Credit Card', 'Debit Card', 'Net Banking', 'Insurance')),
    transaction_ref VARCHAR(100) NOT NULL UNIQUE,
    remarks VARCHAR(255),
    FOREIGN KEY (bill_id) REFERENCES BILL(bill_id) ON DELETE RESTRICT
);

-- INDEXES (Compulsory Requirement: Minimum 2 indexes)
CREATE INDEX idx_appointment_doctor_date ON APPOINTMENT(doctor_id, appointment_date);
CREATE INDEX idx_patient_phone ON PATIENT(phone);
CREATE INDEX idx_bill_payment_status ON BILL(payment_status);
CREATE INDEX idx_visit_patient ON VISIT(patient_id);
