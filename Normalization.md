# Database Normalization Report (1NF to BCNF)
## Group 3: Kolkata City Hospital & Medical Research Centre (KCHMRC)

### 1. Objective of Normalization
Normalization systematically eliminates data redundancy, update anomalies, insertion anomalies, and deletion anomalies while ensuring lossless join decomposition and functional dependency preservation.

---

### 2. First Normal Form (1NF)
**Rule**: All attribute values must be atomic; no multi-valued attributes or repeating groups.
- In initial unnormalized medical records, prescriptions had repeated columns like `Medicine_1`, `Dose_1`, `Medicine_2`, `Dose_2`, etc.
- In 1NF decomposition:
  - Created atomic entity `MEDICINE`.
  - Created atomic bridge entity `PRESCRIPTION_DETAIL` where each row represents exactly one prescribed medication with scalar attributes (`dosage`, `frequency`, `duration_days`, `quantity`).
  - Addresses are stored as atomic clean strings without repeating subgroups.

---

### 3. Second Normal Form (2NF)
**Rule**: The relation must be in 1NF and every non-prime attribute must be fully functionally dependent on the entire primary key (no partial functional dependencies).
- Consider `PRESCRIPTION_DETAIL(prescription_id, medicine_id, dosage, frequency, quantity, medicine_name, unit_price)`:
  - Primary Key: `(prescription_id, medicine_id)`
  - Functional Dependency: `medicine_id -> medicine_name, unit_price`
  - Here, `medicine_name` and `unit_price` depended only on part of the composite primary key (`medicine_id`), which violated 2NF.
- **2NF Resolution**:
  - Split into:
    1. `MEDICINE(medicine_id, medicine_name, generic_name, unit_price, stock_quantity)`
    2. `PRESCRIPTION_DETAIL(item_id, prescription_id, medicine_id, dosage, frequency, duration_days, quantity)`
  - Now, all non-key attributes in `PRESCRIPTION_DETAIL` depend fully on the surrogate primary key `item_id`.

---

### 4. Third Normal Form (3NF)
**Rule**: The relation must be in 2NF and no non-prime attribute should be transitively dependent on the primary key (no transitive functional dependencies $X \rightarrow Y \rightarrow Z$).
- Consider `DOCTOR(doctor_id, first_name, last_name, dept_id, dept_name, head_of_dept, location_block)`:
  - Primary Key: `doctor_id`
  - Functional Dependencies:
    - `doctor_id -> dept_id`
    - `dept_id -> dept_name, head_of_dept, location_block`
  - Transitive Dependency: `doctor_id -> dept_name` via `dept_id`. If all doctors in Cardiology left, hospital department information would be lost (deletion anomaly).
- **3NF Resolution**:
  - Decompose into two independent relations:
    1. `DEPARTMENT(dept_id, dept_name, head_of_dept, location_block, phone_extension)`
    2. `DOCTOR(doctor_id, first_name, last_name, dept_id, qualification, consultation_fee, room_no)`
  - Transitive dependency eliminated.

---

### 5. Boyce-Codd Normal Form (BCNF)
**Rule**: A relation is in BCNF if for every non-trivial functional dependency $X \rightarrow Y$, the determinant $X$ is a superkey.
- Consider `APPOINTMENT(appointment_id, patient_id, doctor_id, appointment_date, time_slot)`:
  - Candidates Keys:
    - $K_1 = \{\text{appointment_id}\}$
    - $K_2 = \{\text{doctor_id}, \text{appointment_date}, \text{time_slot}\}$
  - Functional Dependencies:
    - $\text{appointment_id} \rightarrow \text{patient_id}, \text{doctor_id}, \text{appointment_date}, \text{time_slot}$ (LHS is superkey)
    - $\{\text{doctor_id}, \text{appointment_date}, \text{time_slot}\} \rightarrow \text{appointment_id}, \text{patient_id}$ (LHS is superkey)
  - Since every determinant is a superkey, the table satisfies BCNF.

---

### 6. Summary of Normalized Relations
All 14 tables in the KCHMRC schema satisfy Boyce-Codd Normal Form (BCNF), preserving all functional dependencies while eliminating anomalies.
