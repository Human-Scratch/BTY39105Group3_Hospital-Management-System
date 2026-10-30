from flask import Flask, request, jsonify, session, send_from_directory
from flask_cors import CORS
import os
import json
from config import Config
from db import Database

app = Flask(__name__, static_folder="../frontend", static_url_path="")
app.secret_key = Config.SECRET_KEY
CORS(app, supports_credentials=True)

# Helper: RBAC decorator
def require_roles(*allowed_roles):
    def decorator(fn):
        def wrapper(*args, **kwargs):
            user = session.get("user")
            if not user:
                return jsonify({"error": "Unauthorized. Please log in."}), 401
            if user.get("role") not in allowed_roles:
                return jsonify({
                    "error": f"Forbidden. Role '{user.get('role')}' does not have permission for this resource."
                }), 403
            return fn(*args, **kwargs)
        wrapper.__name__ = fn.__name__
        return wrapper
    return decorator

# ==========================================
# 0. SYSTEM HEALTH & DATABASE ENGINE CHECK
# ==========================================
@app.route("/api/health", methods=["GET"])
def health():
    try:
        conn, engine = Database.get_connection()
        conn.close()
        return jsonify({
            "status": "online",
            "database_engine": engine.upper(),
            "hospital": "Kolkata City Hospital & Medical Research Centre (KCHMRC)"
        })
    except Exception as e:
        return jsonify({"status": "degraded", "error": str(e)}), 500

# ==========================================
# 1. AUTHENTICATION & SESSION
# ==========================================
@app.route("/api/auth/login", methods=["POST"])
def login():
    data = request.json or {}
    identifier = data.get("username_or_email", "").strip()
    password = data.get("password", "").strip()

    sql = '''
        SELECT u.user_id, u.username, u.email, u.password_hash, u.role, 
               u.linked_doctor_id, u.linked_patient_id,
               d.first_name AS doc_first, d.last_name AS doc_last,
               p.first_name AS pat_first, p.last_name AS pat_last
        FROM USER_ACCOUNT u
        LEFT JOIN DOCTOR d ON u.linked_doctor_id = d.doctor_id
        LEFT JOIN PATIENT p ON u.linked_patient_id = p.patient_id
        WHERE (u.username = %s OR u.email = %s) AND u.is_active = 1
    '''
    row = Database.query(sql, (identifier, identifier), fetchone=True)
    if not row:
        return jsonify({"error": "Invalid username or password"}), 401

    stored_hash = row["password_hash"]
    valid = False
    if "pbkdf2_sha256$" in stored_hash:
        expected_pw = stored_hash.split("$")[-1]
        valid = (password == expected_pw)
    elif password == stored_hash:
        valid = True

    if not valid:
        return jsonify({"error": "Invalid username or password"}), 401

    full_name = row["username"]
    if row.get("doc_first"):
        full_name = f"Dr. {row['doc_first']} {row['doc_last']}"
    elif row.get("pat_first"):
        full_name = f"{row['pat_first']} {row['pat_last']}"

    user_info = {
        "user_id": row["user_id"],
        "username": row["username"],
        "email": row["email"],
        "role": row["role"],
        "linked_doctor_id": row.get("linked_doctor_id"),
        "linked_patient_id": row.get("linked_patient_id"),
        "full_name": full_name
    }
    session["user"] = user_info
    return jsonify({"message": "Login successful", "user": user_info})

@app.route("/api/auth/logout", methods=["POST"])
def logout():
    session.pop("user", None)
    return jsonify({"message": "Logged out successfully"})

@app.route("/api/auth/me", methods=["GET"])
def current_user():
    user = session.get("user")
    return jsonify({"user": user})

# ==========================================
# 2. PATIENTS ENDPOINTS
# ==========================================
@app.route("/api/patients", methods=["GET"])
def get_patients():
    user = session.get("user")
    # If patient role, filter strictly to their own MRN
    if user and user.get("role") == "Patient":
        rows = Database.query("SELECT * FROM PATIENT WHERE patient_id = %s", (user.get("linked_patient_id"),))
    else:
        search = request.args.get("search", "").strip()
        if search:
            sql = '''
                SELECT * FROM PATIENT 
                WHERE first_name LIKE %s OR last_name LIKE %s OR phone LIKE %s OR address LIKE %s
                ORDER BY patient_id DESC
            '''
            term = f"%{search}%"
            rows = Database.query(sql, (term, term, term, term))
        else:
            rows = Database.query("SELECT * FROM PATIENT ORDER BY patient_id DESC")
    return jsonify({"patients": rows})

@app.route("/api/patients", methods=["POST"])
@require_roles("Admin", "Manager", "Staff")
def register_patient():
    data = request.json or {}
    required = ["first_name", "last_name", "date_of_birth", "gender", "phone", "address", "emergency_contact"]
    for field in required:
        if not data.get(field):
            return jsonify({"error": f"Field '{field}' is required"}), 400

    sql = '''
        INSERT INTO PATIENT (first_name, last_name, date_of_birth, gender, blood_group, phone, email, address, emergency_contact)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    '''
    try:
        pid = Database.execute(sql, (
            data["first_name"], data["last_name"], data["date_of_birth"], data["gender"],
            data.get("blood_group", "B+"), data["phone"], data.get("email"),
            data["address"], data["emergency_contact"]
        ))
        return jsonify({"message": "Patient registered successfully", "patient_id": pid}), 201
    except Exception as e:
        return jsonify({"error": f"Database insertion error: {str(e)}"}), 400

# ==========================================
# 3. DOCTORS & DEPARTMENTS
# ==========================================
@app.route("/api/doctors", methods=["GET"])
def get_doctors():
    sql = '''
        SELECT d.*, dept.dept_name, dept.location_block
        FROM DOCTOR d
        JOIN DEPARTMENT dept ON d.dept_id = dept.dept_id
        ORDER BY d.doctor_id ASC
    '''
    rows = Database.query(sql)
    return jsonify({"doctors": rows})

@app.route("/api/departments", methods=["GET"])
def get_departments():
    rows = Database.query("SELECT * FROM DEPARTMENT ORDER BY dept_id ASC")
    return jsonify({"departments": rows})

# ==========================================
# 4. APPOINTMENTS (WITH DUPLICATE TRIGGER CATCH)
# ==========================================
@app.route("/api/appointments", methods=["GET"])
def get_appointments():
    user = session.get("user")
    if user and user.get("role") == "Patient":
        sql = '''
            SELECT a.*, p.first_name AS pat_first, p.last_name AS pat_last, p.phone AS pat_phone,
                   d.first_name AS doc_first, d.last_name AS doc_last, d.specialization, d.room_no, dept.dept_name
            FROM APPOINTMENT a
            JOIN PATIENT p ON a.patient_id = p.patient_id
            JOIN DOCTOR d ON a.doctor_id = d.doctor_id
            JOIN DEPARTMENT dept ON d.dept_id = dept.dept_id
            WHERE a.patient_id = %s
            ORDER BY a.appointment_date DESC, a.time_slot ASC
        '''
        rows = Database.query(sql, (user.get("linked_patient_id"),))
    elif user and user.get("role") == "Doctor":
        sql = '''
            SELECT a.*, p.first_name AS pat_first, p.last_name AS pat_last, p.phone AS pat_phone,
                   d.first_name AS doc_first, d.last_name AS doc_last, d.specialization, d.room_no, dept.dept_name
            FROM APPOINTMENT a
            JOIN PATIENT p ON a.patient_id = p.patient_id
            JOIN DOCTOR d ON a.doctor_id = d.doctor_id
            JOIN DEPARTMENT dept ON d.dept_id = dept.dept_id
            WHERE a.doctor_id = %s
            ORDER BY a.appointment_date DESC, a.time_slot ASC
        '''
        rows = Database.query(sql, (user.get("linked_doctor_id"),))
    else:
        sql = '''
            SELECT a.*, p.first_name AS pat_first, p.last_name AS pat_last, p.phone AS pat_phone,
                   d.first_name AS doc_first, d.last_name AS doc_last, d.specialization, d.room_no, dept.dept_name
            FROM APPOINTMENT a
            JOIN PATIENT p ON a.patient_id = p.patient_id
            JOIN DOCTOR d ON a.doctor_id = d.doctor_id
            JOIN DEPARTMENT dept ON d.dept_id = dept.dept_id
            ORDER BY a.appointment_date DESC, a.time_slot ASC
        '''
        rows = Database.query(sql)
    return jsonify({"appointments": rows})

@app.route("/api/appointments", methods=["POST"])
def book_appointment():
    user = session.get("user")
    data = request.json or {}
    patient_id = data.get("patient_id")
    if user and user.get("role") == "Patient":
        patient_id = user.get("linked_patient_id")

    doctor_id = data.get("doctor_id")
    app_date = data.get("appointment_date")
    time_slot = data.get("time_slot")
    reason = data.get("reason", "Outpatient Consultation")

    if not (patient_id and doctor_id and app_date and time_slot):
        return jsonify({"error": "Missing required fields (patient_id, doctor_id, appointment_date, time_slot)"}), 400

    # The MySQL/SQLite Trigger trg_prevent_duplicate_appointment enforces slot uniqueness!
    sql = '''
        INSERT INTO APPOINTMENT (patient_id, doctor_id, appointment_date, time_slot, status, reason)
        VALUES (%s, %s, %s, %s, 'Scheduled', %s)
    '''
    try:
        app_id = Database.execute(sql, (patient_id, doctor_id, app_date, time_slot, reason))
        return jsonify({"message": "Appointment scheduled successfully!", "appointment_id": app_id}), 201
    except Exception as e:
        err = str(e)
        if "CONFLICT" in err or "1062" in err or "UNIQUE" in err:
            return jsonify({
                "error": "CONFLICT: The selected doctor already has a confirmed appointment scheduled for this date and time slot."
            }), 409
        return jsonify({"error": f"Booking failed: {err}"}), 500

@app.route("/api/appointments/<int:app_id>/status", methods=["PUT"])
def update_appointment_status(app_id):
    status = (request.json or {}).get("status", "Completed")
    try:
        Database.execute("UPDATE APPOINTMENT SET status = %s WHERE appointment_id = %s", (status, app_id))
        return jsonify({"message": f"Appointment #{app_id} updated to {status}"})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# ==========================================
# 5. DASHBOARD & FINANCIAL REVENUE (STRICT RBAC)
# ==========================================
@app.route("/api/reports/dashboard", methods=["GET"])
def get_dashboard_metrics():
    user = session.get("user")
    # Strict RBAC: Patients/Customers and Doctors cannot view institutional earnings!
    if user and user.get("role") not in ["Admin", "Manager"]:
        return jsonify({
            "error": "ACCESS RESTRICTED: Institutional financial metrics and revenue dashboards are accessible strictly to Administrators and Hospital Managers."
        }), 403

    kpi_sql = '''
        SELECT 
            (SELECT COUNT(*) FROM PATIENT) AS total_patients,
            (SELECT COUNT(*) FROM DOCTOR WHERE is_available = 1) AS active_doctors,
            (SELECT COUNT(*) FROM APPOINTMENT WHERE status = 'Completed') AS completed_appointments,
            (SELECT COUNT(*) FROM APPOINTMENT WHERE status = 'Scheduled') AS pending_appointments,
            (SELECT COALESCE(SUM(amount_paid), 0) FROM PAYMENT) AS total_revenue_collected,
            (SELECT COALESCE(SUM(net_payable), 0) FROM BILL WHERE payment_status != 'Paid') AS outstanding_dues
    '''
    kpis = Database.query(kpi_sql, fetchone=True)

    dept_rev_sql = '''
        SELECT 
            dept.dept_name,
            COUNT(DISTINCT v.visit_id) AS total_visits,
            COUNT(DISTINCT a.appointment_id) AS total_bookings,
            COALESCE(SUM(b.net_payable), 0) AS department_total_billed
        FROM DEPARTMENT dept
        LEFT JOIN DOCTOR d ON dept.dept_id = d.dept_id
        LEFT JOIN VISIT v ON d.doctor_id = v.doctor_id
        LEFT JOIN APPOINTMENT a ON d.doctor_id = a.doctor_id
        LEFT JOIN BILL b ON v.visit_id = b.visit_id
        GROUP BY dept.dept_id, dept.dept_name
        ORDER BY department_total_billed DESC
    '''
    dept_revenue = Database.query(dept_rev_sql)

    return jsonify({"kpis": kpis, "department_revenue": dept_revenue})

# ==========================================
# 6. SQL QUERY RUNNER STUDIO (ADMIN ONLY)
# ==========================================
@app.route("/api/admin/execute-sql", methods=["POST"])
@require_roles("Admin")
def execute_sql():
    query = (request.json or {}).get("query", "").strip()
    if not query:
        return jsonify({"error": "Empty query"}), 400

    conn, engine = Database.get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(query)
        if query.upper().startswith("SELECT") or query.upper().startswith("SHOW") or query.upper().startswith("DESCRIBE"):
            if engine == "sqlite":
                cols = [desc[0] for desc in cursor.description] if cursor.description else []
                rows = [dict(zip(cols, row)) for row in cursor.fetchall()]
            else:
                rows = cursor.fetchall()
                cols = list(rows[0].keys()) if rows else []
            conn.close()
            return jsonify({"columns": cols, "rows": rows, "count": len(rows), "engine": engine.upper()})
        else:
            conn.commit()
            affected = cursor.rowcount
            conn.close()
            return jsonify({"message": f"Query executed successfully on {engine.upper()}. Rows affected: {affected}"})
    except Exception as e:
        conn.close()
        return jsonify({"error": str(e)}), 400

@app.route("/")
def index():
    return send_from_directory(app.static_folder, "index.html")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
