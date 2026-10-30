# Comprehensive Data Dictionary
## Group 3: Kolkata City Hospital & Medical Research Centre (KCHMRC)

This data dictionary outlines the physical data definitions, column types, nullability, constraints, default values, and operational descriptions for all 14 database tables.

---

### 1. DEPARTMENT
| Column Name | Data Type | Nullable | Key / Constraint | Description |
|---|---|---|---|---|
| `dept_id` | INTEGER | NO | PRIMARY KEY | Unique identifier for medical department |
| `dept_name` | VARCHAR(100) | NO | UNIQUE | Clinical department name (e.g. Cardiology) |
| `head_of_dept` | VARCHAR(100) | NO | None | Name of the Head of Department |
| `location_block`| VARCHAR(50) | NO | None | Physical hospital block and floor location |
| `phone_extension`| VARCHAR(20) | NO | None | Internal PBX extension telephone number |
| `created_at` | TIMESTAMP | YES | DEFAULT CURRENT_TIMESTAMP | Audit creation timestamp |

---

### 2. DOCTOR
| Column Name | Data Type | Nullable | Key / Constraint | Description |
|---|---|---|---|---|
| `doctor_id` | INTEGER | NO | PRIMARY KEY | Unique identifier for medical doctor |
| `first_name` | VARCHAR(50) | NO | None | Doctor's first name |
| `last_name` | VARCHAR(50) | NO | None | Doctor's last name |
| `email` | VARCHAR(100) | NO | UNIQUE | Professional email address |
| `phone` | VARCHAR(20) | NO | UNIQUE | Contact mobile number |
| `specialization`| VARCHAR(100) | NO | None | Medical clinical specialty |
| `dept_id` | INTEGER | NO | FOREIGN KEY -> DEPARTMENT | Department affiliation |
| `qualification` | VARCHAR(100) | NO | None | Educational degrees (MD, MS, DM, etc.) |
| `consultation_fee` | DECIMAL(10,2) | NO | CHECK (fee >= 0) | Outpatient OPD consultation charges (INR) |
| `room_no` | VARCHAR(20) | NO | None | OPD consultation chamber number |
| `is_available` | BOOLEAN | YES | DEFAULT 1 | Current duty status |

---

### 3. PATIENT
| Column Name | Data Type | Nullable | Key / Constraint | Description |
|---|---|---|---|---|
| `patient_id` | INTEGER | NO | PRIMARY KEY | Unique patient registration MRN |
| `first_name` | VARCHAR(50) | NO | None | Patient's given name |
| `last_name` | VARCHAR(50) | NO | None | Patient's surname |
| `date_of_birth` | DATE | NO | None | Date of birth for age calculation |
| `gender` | VARCHAR(10) | NO | CHECK ('Male','Female','Other') | Biological gender |
| `blood_group` | VARCHAR(5) | YES | CHECK standard ABO/Rh groups | ABO and Rh factor blood group |
| `phone` | VARCHAR(20) | NO | UNIQUE | Primary mobile phone |
| `email` | VARCHAR(100) | YES | UNIQUE | Personal email address |
| `address` | TEXT | NO | None | Residential street address in Kolkata |
| `emergency_contact`| VARCHAR(20)| NO | None | Contact phone for next of kin |
| `registration_date`| TIMESTAMP| YES | DEFAULT CURRENT_TIMESTAMP | Initial registration timestamp |

---

### 4. USER_ACCOUNT (RBAC)
| Column Name | Data Type | Nullable | Key / Constraint | Description |
|---|---|---|---|---|
| `user_id` | INTEGER | NO | PRIMARY KEY | Unique user account ID |
| `username` | VARCHAR(50) | NO | UNIQUE | System login handle |
| `email` | VARCHAR(100) | NO | UNIQUE | Authentication email |
| `password_hash` | VARCHAR(255) | NO | None | Secure salted password hash |
| `role` | VARCHAR(20) | NO | CHECK ('Admin','Manager','Doctor','Staff','Patient') | Access role level |
| `linked_doctor_id` | INTEGER | YES | FOREIGN KEY -> DOCTOR | Associated doctor if role is Doctor |
| `linked_patient_id`| INTEGER | YES | FOREIGN KEY -> PATIENT | Associated patient if role is Patient |
| `is_active` | BOOLEAN | YES | DEFAULT 1 | Account activation status |
| `created_at` | TIMESTAMP | YES | DEFAULT CURRENT_TIMESTAMP | Creation timestamp |

---

### 5. APPOINTMENT
| Column Name | Data Type | Nullable | Key / Constraint | Description |
|---|---|---|---|---|
| `appointment_id` | INTEGER | NO | PRIMARY KEY | Unique appointment booking ID |
| `patient_id` | INTEGER | NO | FOREIGN KEY -> PATIENT | Booking patient |
| `doctor_id` | INTEGER | NO | FOREIGN KEY -> DOCTOR | Consulting physician |
| `appointment_date`| DATE | NO | None | Scheduled calendar date |
| `time_slot` | VARCHAR(20) | NO | None | Time interval (e.g. '10:00 AM') |
| `status` | VARCHAR(20) | YES | DEFAULT 'Scheduled' | 'Scheduled', 'Completed', 'Cancelled' |
| `reason` | TEXT | NO | None | Chief presenting medical complaint |
| *Constraint* | UNIQUE | NO | `(doctor_id, appointment_date, time_slot)` | Enforces single booking per doctor slot |

---

### 6. VISIT
| Column Name | Data Type | Nullable | Key / Constraint | Description |
|---|---|---|---|---|
| `visit_id` | INTEGER | NO | PRIMARY KEY | Clinical encounter ID |
| `appointment_id` | INTEGER | YES | FOREIGN KEY -> APPOINTMENT | Source appointment |
| `patient_id` | INTEGER | NO | FOREIGN KEY -> PATIENT | Examined patient |
| `doctor_id` | INTEGER | NO | FOREIGN KEY -> DOCTOR | Attending physician |
| `visit_date` | TIMESTAMP | YES | DEFAULT CURRENT_TIMESTAMP | Time of encounter |
| `symptoms` | TEXT | NO | None | Detailed subjective complaints |
| `blood_pressure` | VARCHAR(20) | YES | Format 'systolic/diastolic' | BP reading (mmHg) |
| `pulse_rate` | INTEGER | YES | CHECK (pulse > 0) | Heart rate in beats per minute |
| `temperature_f` | DECIMAL(4,1)| YES | None | Body temperature in Fahrenheit |
| `weight_kg` | DECIMAL(5,2)| YES | None | Patient weight in kilograms |
| `doctor_notes` | TEXT | YES | None | Clinical findings and observations |

---

### 7. DIAGNOSIS
| Column Name | Data Type | Nullable | Key / Constraint | Description |
|---|---|---|---|---|
| `diagnosis_id` | INTEGER | NO | PRIMARY KEY | Unique diagnosis record ID |
| `visit_id` | INTEGER | NO | FOREIGN KEY -> VISIT | Associated encounter |
| `icd_code` | VARCHAR(20) | NO | None | ICD-10 medical diagnostic code |
| `condition_name` | VARCHAR(150)| NO | None | Clinical disease/condition name |
| `severity` | VARCHAR(20) | YES | CHECK ('Mild','Moderate','Severe','Critical') | Clinical classification |
| `diagnosis_notes`| TEXT | YES | None | Diagnostic rationale |
| `diagnosed_date` | DATE | NO | None | Date of confirmation |

---

### 8. PRESCRIPTION & PRESCRIPTION_DETAIL
| Column Name | Data Type | Nullable | Key / Constraint | Description |
|---|---|---|---|---|
| `prescription_id`| INTEGER | NO | PRIMARY KEY | Prescription header ID |
| `visit_id` | INTEGER | NO | FOREIGN KEY -> VISIT | Originating encounter |
| `doctor_id` | INTEGER | NO | FOREIGN KEY -> DOCTOR | Prescribing doctor |
| `patient_id` | INTEGER | NO | FOREIGN KEY -> PATIENT | Recipient patient |
| `prescription_date`| DATE | NO | None | Date of prescription |
| `advice_notes` | TEXT | YES | None | Lifestyle & dietary instructions |
| `item_id` | INTEGER | NO | PRIMARY KEY in DETAIL | Line item ID |
| `medicine_id` | INTEGER | NO | FOREIGN KEY -> MEDICINE | Dispensed medication |
| `dosage` | VARCHAR(50) | NO | None | Dosage strength (e.g. 500mg) |
| `frequency` | VARCHAR(50) | NO | None | Timing schedule (e.g. Twice daily) |
| `duration_days` | INTEGER | NO | CHECK (> 0) | Treatment course duration |
| `quantity` | INTEGER | NO | CHECK (> 0) | Total units dispensed |

---

### 9. MEDICINE
| Column Name | Data Type | Nullable | Key / Constraint | Description |
|---|---|---|---|---|
| `medicine_id` | INTEGER | NO | PRIMARY KEY | Unique pharmacy catalog ID |
| `medicine_name` | VARCHAR(100)| NO | None | Commercial trade brand name |
| `generic_name` | VARCHAR(100)| NO | None | Active chemical pharmaceutical molecule |
| `category` | VARCHAR(50) | NO | None | Therapeutic classification |
| `dosage_form` | VARCHAR(30) | NO | None | Tablet, Capsule, Syrup, Ointment |
| `unit_price` | DECIMAL(10,2)| NO| CHECK (price >= 0) | Retail sales price per unit (INR) |
| `stock_quantity`| INTEGER | NO | CHECK (stock >= 0) | Units available in hospital store |
| `manufacturer` | VARCHAR(100)| NO | None | Pharmaceutical company name |

---

### 10. LAB_TEST & LAB_TEST_ORDER
| Column Name | Data Type | Nullable | Key / Constraint | Description |
|---|---|---|---|---|
| `test_id` | INTEGER | NO | PRIMARY KEY in LAB_TEST | Diagnostic catalog ID |
| `test_name` | VARCHAR(100)| NO | None | Investigation title |
| `category` | VARCHAR(50) | NO | Pathology, Radiology, Cardiology, etc. | Diagnostic division |
| `standard_fee` | DECIMAL(10,2)| NO| CHECK (fee >= 0) | Standard laboratory charge (INR) |
| `turnaround_hours`| INTEGER | NO | CHECK (> 0) | Estimated reporting lead time |
| `sample_type` | VARCHAR(50) | NO | None | Specimen required (Serum, Urine, etc.) |
| `order_id` | INTEGER | NO | PRIMARY KEY in ORDER | Test requisition ID |
| `visit_id` | INTEGER | NO | FOREIGN KEY -> VISIT | Encounter reference |
| `status` | VARCHAR(20) | YES | DEFAULT 'Ordered' | Ordered, Sample Collected, Completed |
| `result_value` | TEXT | YES | None | Quantitative / qualitative outcome |
| `normal_range` | VARCHAR(100)| YES | None | Reference biological interval |

---

### 11. BILL & PAYMENT
| Column Name | Data Type | Nullable | Key / Constraint | Description |
|---|---|---|---|---|
| `bill_id` | INTEGER | NO | PRIMARY KEY in BILL | Financial invoice number |
| `patient_id` | INTEGER | NO | FOREIGN KEY -> PATIENT | Debtor patient |
| `visit_id` | INTEGER | YES | FOREIGN KEY -> VISIT | Billed clinical encounter |
| `bill_date` | DATE | NO | None | Date of invoice generation |
| `consultation_fee`| DECIMAL(10,2)| NO| DEFAULT 0.00 | OPD consultation charge component |
| `lab_charges` | DECIMAL(10,2)| NO| DEFAULT 0.00 | Aggregate pathology & imaging tests |
| `pharmacy_charges`| DECIMAL(10,2)| NO| DEFAULT 0.00 | Aggregate prescription medicines |
| `total_amount` | DECIMAL(10,2)| NO| CHECK (total >= 0) | Gross invoice subtotal |
| `discount_amount`| DECIMAL(10,2)| NO| CHECK (discount >= 0) | Concession / discount applied |
| `net_payable` | DECIMAL(10,2)| NO| CHECK (net >= 0) | Final net amount owed |
| `payment_status`| VARCHAR(20) | YES| Unpaid, Partially Paid, Paid | Current reconciliation status |
| `payment_id` | INTEGER | NO | PRIMARY KEY in PAYMENT | Payment transaction voucher ID |
| `amount_paid` | DECIMAL(10,2)| NO| CHECK (amount > 0) | Remittance amount in INR |
| `payment_mode` | VARCHAR(30) | NO | Cash, UPI, Credit Card, Debit Card | Settlement channel |
| `transaction_ref`| VARCHAR(100)| NO | UNIQUE | Banking / UPI UTR reference number |
