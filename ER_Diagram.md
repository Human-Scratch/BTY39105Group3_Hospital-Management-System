# Entity-Relationship (ER) Diagram & Conceptual Model
## Group 3: Kolkata City Hospital & Medical Research Centre (KCHMRC)

### 1. Conceptual Model Overview
The Kolkata City Hospital Management System manages healthcare operations across clinical, administrative, and financial domains. The ER model models entities, cardinalities, primary keys, and foreign key relationships.

```mermaid
erDiagram
    DEPARTMENT ||--o{ DOCTOR : employs
    DOCTOR ||--o{ APPOINTMENT : attends
    PATIENT ||--o{ APPOINTMENT : books
    APPOINTMENT ||--o| VISIT : results_in
    PATIENT ||--o{ VISIT : undergoes
    DOCTOR ||--o{ VISIT : conducts
    VISIT ||--o{ DIAGNOSIS : identified_during
    VISIT ||--o{ PRESCRIPTION : generates
    DOCTOR ||--o{ PRESCRIPTION : writes
    PATIENT ||--o{ PRESCRIPTION : receives
    PRESCRIPTION ||--|{ PRESCRIPTION_DETAIL : contains
    MEDICINE ||--o{ PRESCRIPTION_DETAIL : included_in
    VISIT ||--o{ LAB_TEST_ORDER : orders
    PATIENT ||--o{ LAB_TEST_ORDER : takes
    LAB_TEST ||--o{ LAB_TEST_ORDER : categorizes
    VISIT ||--o| BILL : billed_for
    PATIENT ||--o{ BILL : billed_to
    BILL ||--o{ PAYMENT : settled_by
    USER_ACCOUNT ||--o| DOCTOR : authenticates
    USER_ACCOUNT ||--o| PATIENT : authenticates

    DEPARTMENT {
        int dept_id PK
        string dept_name
        string head_of_dept
        string location_block
        string phone_extension
    }

    DOCTOR {
        int doctor_id PK
        int dept_id FK
        string first_name
        string last_name
        string specialization
        string qualification
        decimal consultation_fee
        string room_no
        boolean is_available
    }

    PATIENT {
        int patient_id PK
        string first_name
        string last_name
        date date_of_birth
        string gender
        string blood_group
        string phone
        string address
        string emergency_contact
    }

    APPOINTMENT {
        int appointment_id PK
        int patient_id FK
        int doctor_id FK
        date appointment_date
        string time_slot
        string status
        string reason
    }

    VISIT {
        int visit_id PK
        int appointment_id FK
        int patient_id FK
        int doctor_id FK
        timestamp visit_date
        string symptoms
        string blood_pressure
        int pulse_rate
        decimal temperature_f
        decimal weight_kg
        string doctor_notes
    }

    DIAGNOSIS {
        int diagnosis_id PK
        int visit_id FK
        string icd_code
        string condition_name
        string severity
        date diagnosed_date
    }

    PRESCRIPTION {
        int prescription_id PK
        int visit_id FK
        int doctor_id FK
        int patient_id FK
        date prescription_date
        string advice_notes
    }

    MEDICINE {
        int medicine_id PK
        string medicine_name
        string generic_name
        string category
        string dosage_form
        decimal unit_price
        int stock_quantity
        string manufacturer
    }

    PRESCRIPTION_DETAIL {
        int item_id PK
        int prescription_id FK
        int medicine_id FK
        string dosage
        string frequency
        int duration_days
        int quantity
    }

    LAB_TEST {
        int test_id PK
        string test_name
        string category
        decimal standard_fee
        int turnaround_hours
        string sample_type
    }

    LAB_TEST_ORDER {
        int order_id PK
        int visit_id FK
        int patient_id FK
        int test_id FK
        timestamp order_date
        string status
        string result_value
        string normal_range
    }

    BILL {
        int bill_id PK
        int patient_id FK
        int visit_id FK
        date bill_date
        decimal consultation_fee
        decimal lab_charges
        decimal pharmacy_charges
        decimal total_amount
        decimal discount_amount
        decimal net_payable
        string payment_status
    }

    PAYMENT {
        int payment_id PK
        int bill_id FK
        timestamp payment_date
        decimal amount_paid
        string payment_mode
        string transaction_ref
        string remarks
    }

    USER_ACCOUNT {
        int user_id PK
        string username
        string email
        string password_hash
        string role
        int linked_doctor_id FK
        int linked_patient_id FK
        boolean is_active
    }
```

### 2. Entity Cardinalities & Multiplicities
1. **DEPARTMENT to DOCTOR (1 : N)**: One department employs one or more doctors. Each doctor belongs to exactly one department.
2. **DOCTOR to APPOINTMENT (1 : N)**: A doctor can have multiple scheduled appointments over time.
3. **PATIENT to APPOINTMENT (1 : N)**: A patient can schedule multiple appointments.
4. **APPOINTMENT to VISIT (1 : 1 optional)**: An appointment may culminate in at most one recorded medical visit.
5. **VISIT to DIAGNOSIS (1 : N)**: A consultation visit can result in multiple clinical diagnoses (ICD-10 mapped).
6. **VISIT to PRESCRIPTION (1 : N)**: A visit may produce medical prescriptions.
7. **PRESCRIPTION to MEDICINE (M : N via PRESCRIPTION_DETAIL)**: A prescription details multiple medicines with dosage, frequency, and duration.
8. **VISIT to LAB_TEST_ORDER (1 : N)**: A doctor can order multiple diagnostic laboratory investigations per visit.
9. **VISIT to BILL (1 : 1 optional)**: Each outpatient visit produces a single itemized billing ledger.
10. **BILL to PAYMENT (1 : N)**: A single hospital bill can be settled in multiple installments (part payments or full settlement).
