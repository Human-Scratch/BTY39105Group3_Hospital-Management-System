# BTY39105_Group03_HospitalManagement

## 1. Project Title & Group Allocation
* **Assigned PBL Group**: **Group 3**
* **Project Title**: **Hospital Patient and Appointment Management System**
* **Healthcare Institution**: Kolkata City Hospital & Medical Research Centre (KCHMRC)
* **Campus Locations**: Salt Lake Sector V & Barrackpore, Kolkata, West Bengal
* **Primary Database Management System**: **MySQL Server 8.0+ / MariaDB** (with SQLite fallback)
---

## 2. Problem Statement & Objectives

### Problem Statement
Develop an integrated Hospital Management System for maintaining patient information, doctors, departments, appointments, visits, diagnoses, prescriptions, laboratory tests, billing, and payments. The system provides centralized access to patient and hospital-related information and improves the management of healthcare services across outpatient, diagnostic, and financial domains.

### Core Objectives
1. **Centralized Patient Management**: Real-time electronic medical records (EMR) accessible across OPD chambers.
2. **Conflict-Free Scheduling (Mandatory Advanced Component)**: Database-level slot conflict enforcement via trigger `trg_prevent_duplicate_appointment` preventing overlapping appointments for the same doctor.
3. **Role-Based Access Control (RBAC)**: Strict information separation where Administrators and Managers access financial revenue and operational analytics, while Customers/Patients only view personal clinical history and invoices (institutional earnings are strictly hidden).
4. **End-to-End Clinical & Billing Workflow**: Unbroken flow linking doctor visits, diagnostic tests, pharmacy dispensations, invoice generation, and payment settlement.

---

## 3. Technology Stack & Database Engine
* **Database Management System**: **MySQL Server 8.0+** (InnoDB Engine, utf8mb4 encoding, foreign keys, triggers, stored procedures, transactions) + SQLite fallback engine
* **Backend Framework**: Python 3.10+ / Flask / PyMySQL / mysql-connector-python / Gunicorn
* **Frontend Layer**: Responsive Single-Page Application (HTML5, Tailwind CSS 3.4, JavaScript ES6, Chart.js 4.4, FontAwesome 6.5)
* **Version Control**: Git + GitHub
* **Deployment Target**: Render.com Web Service / XAMPP / Docker / PythonAnywhere

---

## 4. Repository Structure (Proforma Section 8.2)
```
BTY39105_Group03_HospitalManagement/
├── README.md                           # University master documentation
├── run_server.sh                       # 1-Click Linux / macOS server runner
├── run_server.bat                      # 1-Click Windows server runner
├── kolkata_hospital_app.html          # Standalone client-side evaluation app
├── BTY39105_Group03_Project_Report.pdf  # Comprehensive academic project report
│
├── database/                           # Complete MySQL & SQLite Scripts
│   ├── schema_mysql.sql                # MySQL 8.0 DDL: 14 tables, InnoDB, foreign keys & indexes
│   ├── insert_data_mysql.sql           # MySQL DML: 270+ sample records (Kolkata locations)
│   ├── views_mysql.sql                 # MySQL Views: Medical history, Workload, Billing summary
│   ├── triggers_mysql.sql              # MySQL Triggers: Slot conflict, bill update, stock deduction
│   ├── procedures_mysql.sql            # MySQL Stored Procedures, Function & ACID transaction
│   ├── setup_mysql.py                  # Automated Python script to provision MySQL database
│   ├── setup_mysql.sh                  # 1-Click bash script to import into MySQL
│   ├── setup_mysql.bat                 # 1-Click Windows batch script to import into MySQL
│   ├── queries.sql                     # All 30 compulsory rubric queries
│   └── hospital.db                    # Pre-populated SQLite database (fallback engine)
│
├── docs/                               # Detailed Academic Documentation
│   ├── ER_Diagram.md                   # Conceptual ER diagram (Mermaid + text) & cardinalities
│   ├── Relational_Schema.md            # Relational schema with primary/foreign keys
│   ├── Normalization.md                # 1NF, 2NF, 3NF, BCNF mathematical proofs
│   ├── Data_Dictionary.md              # Column-by-column specifications for all 14 tables
│   ├── MySQL_Setup_Guide.md            # Step-by-step MySQL XAMPP/Workbench/Docker setup guide
│   └── Testing_Report.md               # Test matrix, trigger tests, and verification evidence
│
├── src/                                # Application Source Code
│   ├── backend/
│   │   ├── app.py                      # Flask REST API with role-based middleware
│   │   ├── config.py                   # MySQL connection configuration (Host, User, Port, DB)
│   │   ├── db.py                       # Universal DB adapter (MySQL with SQLite fallback)
│   │   ├── init_db.py                  # SQLite database bootstrapper
│   │   ├── test_queries.py            # Automated SQL query execution tester (30 queries)
│   │   └── requirements.txt            # Python dependencies (PyMySQL, mysql-connector, Flask)
│   └── frontend/
│       └── index.html                  # Full Single-Page Application frontend
│
├── screenshots/                        # High-Resolution UI & Testing Screenshots
│   ├── 01_executive_dashboard.png
│   ├── 02_appointments_management.png
│   ├── 03_trigger_slot_conflict_block.png
│   ├── 04_patient_directory.png
│   ├── 05_doctor_specialties.png
│   ├── 06_clinical_prescriptions.png
│   ├── 07_pathology_labs.png
│   ├── 08_billing_settlements.png
│   └── 09_sql_evaluation_studio.png
│
└── deployment/
    └── deployment_details.md           # Cloud & local deployment guide
```

---

## 5. MySQL Database Setup Instructions

### Option 1: Automated Setup via Python (Recommended)
Make sure your MySQL server is running (e.g. via XAMPP or native service), then run:
```bash
# 1. Install dependencies
pip install -r src/backend/requirements.txt

# 2. Run the automated MySQL provisioning script
python3 database/setup_mysql.py
```
*This automatically connects to MySQL, creates database `kolkata_hospital_db`, and loads all 14 tables, 270+ seed records, views, triggers, and stored procedures.*

### Option 2: 1-Click Import via Command Line
```bash
# On Linux / macOS:
./database/setup_mysql.sh

# On Windows:
database\setup_mysql.bat
```

### Option 3: Manual Import in phpMyAdmin (XAMPP / WAMP)
1. Open `http://localhost/phpmyadmin`
2. Create a new database named `kolkata_hospital_db` (Collation: `utf8mb4_unicode_ci`).
3. Select `kolkata_hospital_db`, click **Import**, and import in order:
   - `database/schema_mysql.sql`
   - `database/insert_data_mysql.sql`
   - `database/views_mysql.sql`
   - `database/triggers_mysql.sql`
   - `database/procedures_mysql.sql`

---

## 6. How to Run the Web Application

```bash
# 1. Setup virtual environment
python3 -m venv venv
source venv/bin/activate       # On Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r src/backend/requirements.txt

# 3. Start the application server
python3 src/backend/app.py
```

Open your browser at **`http://127.0.0.1:5000`**. The application will automatically connect to MySQL Server and display `Backend: MYSQL Connected` in the top header.

---

## 7. Demo Credentials for Evaluation

| Role | Username / Email | Password | Privileges & Access Scope |
|---|---|---|---|
| **Admin** | `admin@kolkatacare.in` | `admin123` | Full Master Access: Financial revenue, doctors, staff, user management, SQL query engine |
| **Hospital Manager** | `manager@kolkatacare.in` | `manager123` | Operational & Financial Access: All analytics, inventory, billing, doctor workload reports |
| **Doctor** | `dr.mukherjee@kolkatacare.in` | `doc123` | Clinical Access: Assigned appointments, patient history, write prescriptions, view lab results |
| **Reception / Staff** | `staff@kolkatacare.in` | `staff123` | Front-Desk Access: Patient registration, appointment scheduling, billing, payments |
| **Patient / Customer** | `rahul.sen@gmail.com` | `patient123` | Customer Access: View personal appointments, prescriptions, bills, lab reports, book visits. **FINANCIAL REVENUE & REVENUE ANALYTICS ARE STRICTLY HIDDEN.** |

---

## 8. Verifying Advanced MySQL Components During Viva

1. **Test Trigger (Slot Conflict Prevention)**:
   Attempt to book **Dr. Anirban Mukherjee** on **2026-10-15 at 09:30 AM** (Appointment #1 slot).  
   *Result*: `trg_prevent_duplicate_appointment` raises `SIGNAL SQLSTATE '45000'` aborting insertion.
2. **Test Stored Procedure (`sp_book_appointment`)**:
   ```sql
   CALL sp_book_appointment(3, 2, '2026-11-20', '10:00 AM', 'Neurology consultation', @new_id, @msg);
   SELECT @new_id AS appointment_id, @msg AS result_status;
   ```
3. **Test Stored Function (`fn_calculate_patient_balance`)**:
   ```sql
   SELECT fn_calculate_patient_balance(20) AS total_unpaid_due;
   ```
4. **Test ACID Transaction**:
   Consultation checkout demonstration in `database/procedures_mysql.sql`.
