# Relational Database Schema & Integrity Constraints
## Group 3: Kolkata City Hospital & Medical Research Centre (KCHMRC)

### 1. Relational Schema Representation
Primary keys are underlined with `[PK]`, and Foreign keys are indicated with `[FK -> Table(Column)]`.

- **DEPARTMENT** ([PK] `dept_id`, `dept_name`, `head_of_dept`, `location_block`, `phone_extension`, `created_at`)
- **DOCTOR** ([PK] `doctor_id`, `first_name`, `last_name`, `email`, `phone`, `specialization`, [FK -> DEPARTMENT(dept_id)] `dept_id`, `qualification`, `consultation_fee`, `room_no`, `is_available`)
- **PATIENT** ([PK] `patient_id`, `first_name`, `last_name`, `date_of_birth`, `gender`, `blood_group`, `phone`, `email`, `address`, `emergency_contact`, `registration_date`)
- **USER_ACCOUNT** ([PK] `user_id`, `username`, `email`, `password_hash`, `role`, [FK -> DOCTOR(doctor_id)] `linked_doctor_id`, [FK -> PATIENT(patient_id)] `linked_patient_id`, `is_active`, `created_at`)
- **APPOINTMENT** ([PK] `appointment_id`, [FK -> PATIENT(patient_id)] `patient_id`, [FK -> DOCTOR(doctor_id)] `doctor_id`, `appointment_date`, `time_slot`, `status`, `reason`, `created_at`)
  - *Composite Unique Constraint / Slot Locking*: `UNIQUE(doctor_id, appointment_date, time_slot)`
- **VISIT** ([PK] `visit_id`, [FK -> APPOINTMENT(appointment_id)] `appointment_id`, [FK -> PATIENT(patient_id)] `patient_id`, [FK -> DOCTOR(doctor_id)] `doctor_id`, `visit_date`, `symptoms`, `blood_pressure`, `pulse_rate`, `temperature_f`, `weight_kg`, `doctor_notes`)
- **DIAGNOSIS** ([PK] `diagnosis_id`, [FK -> VISIT(visit_id)] `visit_id`, `icd_code`, `condition_name`, `severity`, `diagnosis_notes`, `diagnosed_date`)
- **PRESCRIPTION** ([PK] `prescription_id`, [FK -> VISIT(visit_id)] `visit_id`, [FK -> DOCTOR(doctor_id)] `doctor_id`, [FK -> PATIENT(patient_id)] `patient_id`, `prescription_date`, `advice_notes`)
- **MEDICINE** ([PK] `medicine_id`, `medicine_name`, `generic_name`, `category`, `dosage_form`, `unit_price`, `stock_quantity`, `manufacturer`)
- **PRESCRIPTION_DETAIL** ([PK] `item_id`, [FK -> PRESCRIPTION(prescription_id)] `prescription_id`, [FK -> MEDICINE(medicine_id)] `medicine_id`, `dosage`, `frequency`, `duration_days`, `quantity`)
- **LAB_TEST** ([PK] `test_id`, `test_name`, `category`, `standard_fee`, `turnaround_hours`, `sample_type`)
- **LAB_TEST_ORDER** ([PK] `order_id`, [FK -> VISIT(visit_id)] `visit_id`, [FK -> PATIENT(patient_id)] `patient_id`, [FK -> LAB_TEST(test_id)] `test_id`, `order_date`, `status`, `result_value`, `normal_range`, `technician_remarks`)
- **BILL** ([PK] `bill_id`, [FK -> PATIENT(patient_id)] `patient_id`, [FK -> VISIT(visit_id)] `visit_id`, `bill_date`, `consultation_fee`, `lab_charges`, `pharmacy_charges`, `total_amount`, `discount_amount`, `net_payable`, `payment_status`)
- **PAYMENT** ([PK] `payment_id`, [FK -> BILL(bill_id)] `bill_id`, `payment_date`, `amount_paid`, `payment_mode`, `transaction_ref`, `remarks`)

### 2. Integrity Constraints Enforced
1. **Domain Integrity**:
   - `GENDER IN ('Male', 'Female', 'Other')`
   - `BLOOD_GROUP IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')`
   - `APPOINTMENT.status IN ('Scheduled', 'Completed', 'Cancelled', 'No-Show')`
   - `BILL.payment_status IN ('Unpaid', 'Partially Paid', 'Paid')`
   - `PAYMENT.payment_mode IN ('Cash', 'UPI', 'Credit Card', 'Debit Card', 'Net Banking', 'Insurance')`
2. **Referential Integrity**:
   - `ON DELETE RESTRICT` on core master tables (`DOCTOR`, `PATIENT`, `DEPARTMENT`) to prevent orphan records.
   - `ON DELETE CASCADE` on detail tables (`PRESCRIPTION_DETAIL`, `DIAGNOSIS`) to maintain transactional cleanups.
3. **Enterprise Business Rules (DBMS Advanced Trigger)**:
   - A doctor cannot be scheduled for two concurrent appointments at the same date and time slot (`uq_doctor_slot` + `trg_prevent_duplicate_appointment`).
