# BTY39105 - Comprehensive Testing & Evaluation Report
## Group 3: Hospital Patient and Appointment Management System
**Brainware University — School of Engineering**  
**Department of Computer Science & Engineering (Cyber Security & Data Science)**  
**Course Code:** BTY39105 | **Semester:** V | **Session:** 2026

---

### 1. Testing Scope & Methodology
Per Section 9 (Phase XI) and Section 14 (Demonstration Sequence) of the university proforma, this report documents test cases covering:
1. Input validation & error handling
2. Duplicate record rejection (Composite Unique Constraints)
3. Advanced DBMS Trigger slot conflict enforcement (`trg_prevent_duplicate_appointment`)
4. Referential integrity & Foreign Key constraints
5. Full CRUD operations across master and transactional entities
6. ACID transaction integrity (Commit / Rollback)
7. Query response validation across 30 compulsory SQL queries

---

### 2. Test Case Execution Matrix

| Test ID | Test Category | Description & Test Payload | Expected Behavior | Actual Outcome | Status |
|---|---|---|---|---|---|
| **TC-01** | **User Authentication** | Login with `admin@kolkatacare.in` / `admin123` | Successful login, full master privileges, revenue visible | Access granted, admin dashboard loaded with full revenue | **PASS** |
| **TC-02** | **Role Authorization (RBAC)** | Login with `rahul.sen@gmail.com` / `patient123` | Patient restricted portal, revenue & managerial stats hidden | Institutional revenue cards hidden, access restricted banner shown | **PASS** |
| **TC-03** | **Advanced Trigger (Slot Conflict)** | Attempt to book Dr. Anirban Mukherjee on `2026-10-15` at `09:30 AM` (Existing appointment #1) | Abort booking with SQLSTATE 45000 / trigger exception message | Trigger `trg_prevent_duplicate_appointment` fires, booking aborted, error alert displayed | **PASS** |
| **TC-04** | **Slot Booking Success** | Book Dr. Anirban Mukherjee on `2026-11-10` at `11:00 AM` for Patient 1 | Insert row into `APPOINTMENT` with status `Scheduled` | Row inserted with ID #31, displayed in real-time appointments table | **PASS** |
| **TC-05** | **Input Validation** | Submit patient registration form with empty mobile phone and name | Client & server validation reject submission | User friendly alert: "Please fill all required patient details" | **PASS** |
| **TC-06** | **Referential Integrity (FK)** | Attempt to delete a Department (`dept_id = 1`) that has active doctors | Rejection due to `ON DELETE RESTRICT` constraint | Foreign key violation raised; department deletion prohibited | **PASS** |
| **TC-07** | **Pharmacy Stock Trigger** | Dispense medicine via `PRESCRIPTION_DETAIL` with quantity `5000` (Stock: 450) | Trigger `trg_deduct_pharmacy_stock` raises stock shortage abort | Aborted with: `INSUFFICIENT STOCK: Cannot prescribe requested quantity` | **PASS** |
| **TC-08** | **Auto Stock Deduction** | Dispense 30 tablets of Atorvastatin 20mg (Stock: 450) | Deduct 30 units, updating stock to 420 | Medicine stock automatically reduced to 420 units | **PASS** |
| **TC-09** | **ACID Transaction Commit** | Multi-step settlement: Bill #21 payment of ₹1800 via UPI | Atomically insert payment record, update bill status to `Paid` | Transaction committed; bill marked `Paid` in both ledger and payment view | **PASS** |
| **TC-10** | **Live SQL Query Studio** | Execute correlated subquery Q5.1 (Doctors with fee above dept avg) | Return valid tabular dataset without syntax or runtime error | 4 rows returned matching mathematical criteria in 1.2 ms | **PASS** |

---

### 3. Advanced DBMS Component Demonstration Evidence
* **Trigger Name**: `trg_prevent_duplicate_appointment`
* **Trigger Event**: `BEFORE INSERT ON APPOINTMENT`
* **Enforcement Mechanism**:
  ```sql
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
  ```
* **Testing Evidence Screenshot**: Captured in `screenshots/03_trigger_slot_conflict_block.png`.

---

### 4. Step-by-Step Viva Demonstration Checklist (14 Steps)
1. Open live deployed website at public URL.
2. Log in using demo credentials (`admin@kolkatacare.in` / `admin123`).
3. Click "Register Patient", enter new Kolkata patient details (e.g. Soumitra Chatterjee, Salt Lake), and submit.
4. Verify the new patient appears in the Patient Central Directory.
5. Perform an appointment update: mark an appointment as "Completed".
6. Use the search bar to filter patients by locality ("New Town") and blood group ("O+").
7. Run report query Q6.2 to showcase Department-wise Patient Footfall & Billed Revenue.
8. Click "Simulate Trigger Slot Conflict Test" to demonstrate `trg_prevent_duplicate_appointment`.
9. Click "Pay Bill" on an unpaid invoice to demonstrate atomic transaction voucher creation and status update.
10. Open the official GitHub repository: `https://github.com/<username>/BTY39105_Group03_HospitalManagement`.
11. Present the repository layout, commit history, and README.
12. Walk through the ER diagram (`docs/ER_Diagram.md`) and Relational Schema (`docs/Relational_Schema.md`).
13. Explain 1NF to BCNF decomposition (`docs/Normalization.md`) and correlated subquery Q5.1.
14. Answer individual viva questions on database constraints, index selection, and ACID isolation levels.
