-- =====================================================================
-- DATABASE SCHEMA (MySQL 8.0+ / MariaDB)
-- Kolkata City Hospital & Medical Research Centre (KCHMRC)
-- Group 3: Hospital Patient and Appointment Management System
-- Course Code: BTY39105 | Brainware University
-- =====================================================================

CREATE DATABASE IF NOT EXISTS kolkata_hospital_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE kolkata_hospital_db;

-- Drop existing tables in reverse dependency order
SET FOREIGN_KEY_CHECKS = 0;
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
SET FOREIGN_KEY_CHECKS = 1;

-- 1. DEPARTMENT TABLE
CREATE TABLE DEPARTMENT (
    dept_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL UNIQUE,
    head_of_dept VARCHAR(100) NOT NULL,
    location_block VARCHAR(50) NOT NULL,
    phone_extension VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. DOCTOR TABLE
CREATE TABLE DOCTOR (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL UNIQUE,
    specialization VARCHAR(100) NOT NULL,
    dept_id INT NOT NULL,
    qualification VARCHAR(100) NOT NULL,
    consultation_fee DECIMAL(10, 2) NOT NULL CHECK (consultation_fee >= 0),
    room_no VARCHAR(20) NOT NULL,
    is_available BOOLEAN DEFAULT 1,
    FOREIGN KEY (dept_id) REFERENCES DEPARTMENT(dept_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. PATIENT TABLE
CREATE TABLE PATIENT (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    blood_group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') DEFAULT 'B+',
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100) UNIQUE,
    address TEXT NOT NULL,
    emergency_contact VARCHAR(20) NOT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. USER_ACCOUNT (Role-based access control: Admin, Manager, Doctor, Staff, Patient)
CREATE TABLE USER_ACCOUNT (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('Admin', 'Manager', 'Doctor', 'Staff', 'Patient') NOT NULL,
    linked_doctor_id INT NULL,
    linked_patient_id INT NULL,
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (linked_doctor_id) REFERENCES DOCTOR(doctor_id) ON DELETE SET NULL,
    FOREIGN KEY (linked_patient_id) REFERENCES PATIENT(patient_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. APPOINTMENT TABLE (Enforcing slot integrity)
CREATE TABLE APPOINTMENT (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    time_slot VARCHAR(20) NOT NULL,
    status ENUM('Scheduled', 'Completed', 'Cancelled', 'No-Show') DEFAULT 'Scheduled',
    reason TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_doctor_slot UNIQUE (doctor_id, appointment_date, time_slot),
    FOREIGN KEY (patient_id) REFERENCES PATIENT(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (doctor_id) REFERENCES DOCTOR(doctor_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. VISIT TABLE (Outpatient consultation encounter)
CREATE TABLE VISIT (
    visit_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT UNIQUE NULL,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    visit_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    symptoms TEXT NOT NULL,
    blood_pressure VARCHAR(20),
    pulse_rate INT CHECK (pulse_rate > 0),
    temperature_f DECIMAL(4, 1),
    weight_kg DECIMAL(5, 2),
    doctor_notes TEXT,
    FOREIGN KEY (appointment_id) REFERENCES APPOINTMENT(appointment_id) ON DELETE SET NULL,
    FOREIGN KEY (patient_id) REFERENCES PATIENT(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (doctor_id) REFERENCES DOCTOR(doctor_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. DIAGNOSIS TABLE
CREATE TABLE DIAGNOSIS (
    diagnosis_id INT AUTO_INCREMENT PRIMARY KEY,
    visit_id INT NOT NULL,
    icd_code VARCHAR(20) NOT NULL,
    condition_name VARCHAR(150) NOT NULL,
    severity ENUM('Mild', 'Moderate', 'Severe', 'Critical') DEFAULT 'Moderate',
    diagnosis_notes TEXT,
    diagnosed_date DATE NOT NULL,
    FOREIGN KEY (visit_id) REFERENCES VISIT(visit_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. PRESCRIPTION TABLE
CREATE TABLE PRESCRIPTION (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    visit_id INT NOT NULL,
    doctor_id INT NOT NULL,
    patient_id INT NOT NULL,
    prescription_date DATE NOT NULL,
    advice_notes TEXT,
    FOREIGN KEY (visit_id) REFERENCES VISIT(visit_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES DOCTOR(doctor_id) ON DELETE RESTRICT,
    FOREIGN KEY (patient_id) REFERENCES PATIENT(patient_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. MEDICINE TABLE (Hospital Pharmacy Catalog)
CREATE TABLE MEDICINE (
    medicine_id INT AUTO_INCREMENT PRIMARY KEY,
    medicine_name VARCHAR(100) NOT NULL,
    generic_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    dosage_form VARCHAR(30) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    manufacturer VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. PRESCRIPTION_DETAIL TABLE
CREATE TABLE PRESCRIPTION_DETAIL (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    prescription_id INT NOT NULL,
    medicine_id INT NOT NULL,
    dosage VARCHAR(50) NOT NULL,
    frequency VARCHAR(50) NOT NULL,
    duration_days INT NOT NULL CHECK (duration_days > 0),
    quantity INT NOT NULL CHECK (quantity > 0),
    FOREIGN KEY (prescription_id) REFERENCES PRESCRIPTION(prescription_id) ON DELETE CASCADE,
    FOREIGN KEY (medicine_id) REFERENCES MEDICINE(medicine_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. LAB_TEST TABLE (Diagnostic Catalog)
CREATE TABLE LAB_TEST (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(100) NOT NULL,
    category ENUM('Pathology', 'Radiology', 'Biochemistry', 'Microbiology', 'Cardiology') NOT NULL,
    standard_fee DECIMAL(10, 2) NOT NULL CHECK (standard_fee >= 0),
    turnaround_hours INT NOT NULL CHECK (turnaround_hours > 0),
    sample_type VARCHAR(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. LAB_TEST_ORDER TABLE
CREATE TABLE LAB_TEST_ORDER (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    visit_id INT NOT NULL,
    patient_id INT NOT NULL,
    test_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('Ordered', 'Sample Collected', 'In-Process', 'Completed') DEFAULT 'Ordered',
    result_value TEXT,
    normal_range VARCHAR(100),
    technician_remarks TEXT,
    FOREIGN KEY (visit_id) REFERENCES VISIT(visit_id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES PATIENT(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (test_id) REFERENCES LAB_TEST(test_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. BILL TABLE (Financial Invoicing)
CREATE TABLE BILL (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    visit_id INT UNIQUE NULL,
    bill_date DATE NOT NULL,
    consultation_fee DECIMAL(10, 2) DEFAULT 0.00,
    lab_charges DECIMAL(10, 2) DEFAULT 0.00,
    pharmacy_charges DECIMAL(10, 2) DEFAULT 0.00,
    total_amount DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
    discount_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (discount_amount >= 0),
    net_payable DECIMAL(10, 2) NOT NULL CHECK (net_payable >= 0),
    payment_status ENUM('Unpaid', 'Partially Paid', 'Paid') DEFAULT 'Unpaid',
    FOREIGN KEY (patient_id) REFERENCES PATIENT(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (visit_id) REFERENCES VISIT(visit_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14. PAYMENT TABLE (Transaction Settlement)
CREATE TABLE PAYMENT (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    bill_id INT NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount_paid DECIMAL(10, 2) NOT NULL CHECK (amount_paid > 0),
    payment_mode ENUM('Cash', 'UPI', 'Credit Card', 'Debit Card', 'Net Banking', 'Insurance') NOT NULL,
    transaction_ref VARCHAR(100) NOT NULL UNIQUE,
    remarks VARCHAR(255),
    FOREIGN KEY (bill_id) REFERENCES BILL(bill_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PERFORMANCE INDEXES (Compulsory Requirement: Minimum 2)
CREATE INDEX idx_appointment_doctor_date ON APPOINTMENT(doctor_id, appointment_date);
CREATE INDEX idx_patient_phone ON PATIENT(phone);
CREATE INDEX idx_bill_payment_status ON BILL(payment_status);
CREATE INDEX idx_visit_patient ON VISIT(patient_id);
