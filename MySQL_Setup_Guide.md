# MySQL Server Complete Setup & Deployment Guide
## Kolkata City Hospital & Medical Research Centre (KCHMRC)
**Course Code: BTY39105 | Brainware University DBMS Lab**

This guide provides step-by-step instructions for running the hospital management system using **MySQL Server 8.0+ / MariaDB** across XAMPP, MySQL Workbench, Docker, and Python Flask.

---

### 1. Database Architecture & MySQL Files Overview

All MySQL-specific scripts are located in the `database/` directory:

| Filename | Purpose | Engine & Features |
|---|---|---|
| **`schema_mysql.sql`** | Complete DDL schema | 14 Normalized Tables, `ENGINE=InnoDB`, `utf8mb4`, `AUTO_INCREMENT`, Foreign Keys, Domain Constraints, Composite Unique Indexes |
| **`insert_data_mysql.sql`** | Complete DML seed data | 270+ realistic sample records with Kolkata locations |
| **`views_mysql.sql`** | Database Views | 3 Production Views (`v_patient_medical_history`, `v_doctor_workload_metrics`, `v_billing_financial_summary`) |
| **`triggers_mysql.sql`** | Advanced DBMS Triggers | `trg_prevent_duplicate_appointment` (Slot Conflict), `trg_update_bill_on_payment`, `trg_deduct_pharmacy_stock` using `DELIMITER $$` and `SIGNAL SQLSTATE '45000'` |
| **`procedures_mysql.sql`** | Stored Procedures & Transaction | `sp_book_appointment`, `sp_generate_final_bill`, function `fn_calculate_patient_balance`, and ACID transaction |
| **`setup_mysql.py`** | Automated Python Seeder | Connects to MySQL, creates database `kolkata_hospital_db`, and executes all SQL scripts automatically |
| **`setup_mysql.sh` / `.bat`** | 1-Click Shell/Batch Importer | Native command-line import scripts for Linux, macOS, and Windows |

---

### 2. Method A: Setup Using XAMPP / WAMP (Recommended for Lab & Viva)

1. **Start Apache and MySQL**:
   * Open the **XAMPP Control Panel**.
   * Click **Start** next to **Apache** and **MySQL**.
   * Verify MySQL is running on port `3306`.

2. **Option A.1 — Automated Setup via Python**:
   Open a terminal in the project directory and run:
   ```bash
   pip install pymysql cryptography
   python database/setup_mysql.py
   ```
   *This creates `kolkata_hospital_db` and loads all 14 tables, triggers, procedures, views, and 270+ records automatically!*

3. **Option A.2 — Manual Import via phpMyAdmin**:
   * Open your browser and visit: `http://localhost/phpmyadmin`
   * Click **New** in the left sidebar, enter database name: `kolkata_hospital_db`, collation `utf8mb4_unicode_ci`, and click **Create**.
   * Select `kolkata_hospital_db`.
   * Click the **Import** tab:
     * Import `database/schema_mysql.sql` &rarr; click **Go**.
     * Import `database/insert_data_mysql.sql` &rarr; click **Go**.
     * Import `database/views_mysql.sql` &rarr; click **Go**.
     * Import `database/triggers_mysql.sql` &rarr; click **Go**.
     * Import `database/procedures_mysql.sql` &rarr; click **Go**.

---

### 3. Method B: Setup Using MySQL Command Line (CLI)

```bash
# 1. Login to MySQL Server
mysql -u root -p

# 2. Run the provided 1-click script
# On Linux / macOS:
./database/setup_mysql.sh

# On Windows:
database\setup_mysql.bat
```

Or execute directly from the terminal:
```bash
mysql -u root -p < database/schema_mysql.sql
mysql -u root -p kolkata_hospital_db < database/insert_data_mysql.sql
mysql -u root -p kolkata_hospital_db < database/views_mysql.sql
mysql -u root -p kolkata_hospital_db < database/triggers_mysql.sql
mysql -u root -p kolkata_hospital_db < database/procedures_mysql.sql
```

---

### 4. Method C: Setup Using Docker (Zero-Install MySQL)

If you have Docker installed, launch a fully configured MySQL 8.0 container with one command:
```bash
docker run --name mysql-kolkata-hospital \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=kolkata_hospital_db \
  -p 3306:3306 \
  -d mysql:8.0
```

Then initialize the database:
```bash
export MYSQL_PASSWORD=root
python3 database/setup_mysql.py
```

---

### 5. Connecting the Python Flask Backend to MySQL

The backend is configured to automatically connect to MySQL via `src/backend/config.py`.

#### Setting Environment Variables (Optional)
If your MySQL server has custom credentials, set them in your terminal:
```bash
# On Linux / macOS:
export MYSQL_HOST=localhost
export MYSQL_PORT=3306
export MYSQL_USER=root
export MYSQL_PASSWORD=your_password
export MYSQL_DB=kolkata_hospital_db

# On Windows (cmd):
set MYSQL_HOST=localhost
set MYSQL_PORT=3306
set MYSQL_USER=root
set MYSQL_PASSWORD=your_password
set MYSQL_DB=kolkata_hospital_db
```

#### Starting the Full-Stack Web Application:
```bash
# 1. Activate your virtual environment
source venv/bin/activate    # Windows: venv\Scripts\activate

# 2. Install dependencies (including PyMySQL and mysql-connector-python)
pip install -r src/backend/requirements.txt

# 3. Start Flask Backend Server
python3 src/backend/app.py
```

The server will print:
```
 * Running on http://127.0.0.1:5000
 [DB] Successfully connected to MySQL Server (Engine: MYSQL)
```

Now open `http://127.0.0.1:5000` in your web browser. The website will display:
`Backend: MySQL 8.0 Connected` in the top header.

---

### 6. Verifying Advanced MySQL Components During Viva

1. **Test Trigger (Slot Conflict Prevention)**:
   In MySQL Workbench or the website, execute:
   ```sql
   INSERT INTO APPOINTMENT (patient_id, doctor_id, appointment_date, time_slot, status, reason)
   VALUES (2, 1, '2026-10-15', '09:30 AM', 'Scheduled', 'Testing duplicate slot error');
   ```
   **Expected Output**:
   ```
   ERROR 1644 (45000): CONFLICT: The selected doctor already has a confirmed appointment scheduled for this date and time slot.
   ```

2. **Test Stored Procedure (`sp_book_appointment`)**:
   ```sql
   CALL sp_book_appointment(3, 2, '2026-11-20', '10:00 AM', 'Neurology checkup', @new_id, @msg);
   SELECT @new_id AS appointment_id, @msg AS result_status;
   ```

3. **Test Stored Function (`fn_calculate_patient_balance`)**:
   ```sql
   SELECT fn_calculate_patient_balance(20) AS total_outstanding_due;
   ```
