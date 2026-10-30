# Deployment & Setup Guide
## Group 3: Kolkata City Hospital & Medical Research Centre (KCHMRC)

This document provides complete instructions for local setup, database provisioning, and production cloud deployment.

---

### 1. Technology Stack
- **Database**: SQLite (built-in, zero-config) / MySQL 8.0+ / PostgreSQL 14+
- **Backend API**: Python 3.10+ / Flask / Flask-CORS / Werkzeug Security
- **Frontend**: Responsive Single-Page Application (HTML5, Tailwind CSS, JavaScript ES6, FontAwesome Icons, Chart.js)
- **Deployment Targets**: Render, Railway, Vercel, PythonAnywhere, or Docker

---

### 2. Local Environment Setup

#### Prerequisites
- Python 3.10 or higher
- Git
- Modern Web Browser (Chrome, Firefox, Safari, Edge)

#### Step-by-Step Execution
1. **Clone the repository**:
   ```bash
   git clone https://github.com/kolkata-hospital-system/group3-hospital-management.git
   cd group3-hospital-management
   ```

2. **Create and activate a virtual environment**:
   ```bash
   python3 -m venv venv
   # On macOS/Linux:
   source venv/bin/activate
   # On Windows:
   venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r src/backend/requirements.txt
   ```

4. **Initialize Database**:
   ```bash
   python3 src/backend/init_db.py
   ```
   *This initializes SQLite `hospital.db` and loads schema, indexes, views, triggers, and 200+ sample records.*

5. **Start the Backend Web Server**:
   ```bash
   python3 src/backend/app.py
   ```
   *The server starts on `http://127.0.0.1:5000`.*

6. **Access the Website**:
   Open `http://127.0.0.1:5000` or open `src/frontend/index.html` in your web browser.

---

### 3. Production Cloud Deployment (Render.com Free Tier)

1. **Repository Preparation**:
   Ensure `src/backend/requirements.txt` contains:
   ```txt
   Flask==3.0.3
   Flask-Cors==4.0.1
   gunicorn==22.0.0
   ```

2. **Render Web Service Configuration**:
   - Create a new **Web Service** on [Render.com](https://render.com).
   - Connect your GitHub repository.
   - Configure settings:
     - **Name**: `kolkata-city-hospital`
     - **Environment**: `Python 3`
     - **Region**: `Singapore (ap-southeast-1)` (Closest to Kolkata for minimum latency)
     - **Branch**: `main`
     - **Build Command**: `pip install -r src/backend/requirements.txt && python3 src/backend/init_db.py`
     - **Start Command**: `gunicorn --chdir src/backend app:app --bind 0.0.0.0:$PORT`

3. **Live Deployed URL**:
   `https://kolkata-city-hospital.onrender.com`

---

### 4. Demo Login Credentials (Role-Based Access)

| Role | Username / Email | Password | Privileges & Access Scope |
|---|---|---|---|
| **Admin** | `admin@kolkatacare.in` | `admin123` | Full Master Access: Financial revenue, doctors, staff, user management, SQL query engine |
| **Hospital Manager** | `manager@kolkatacare.in` | `manager123` | Operational & Financial Access: All analytics, inventory, billing, doctor workload reports |
| **Doctor** | `dr.mukherjee@kolkatacare.in` | `doc123` | Clinical Access: Assigned appointments, patient history, write prescriptions, view lab results |
| **Reception / Staff** | `staff@kolkatacare.in` | `staff123` | Front-Desk Access: Patient registration, appointment scheduling, billing, payments |
| **Patient / Customer** | `rahul.sen@gmail.com` | `patient123` | Customer Access: View personal appointments, prescriptions, bills, lab reports, book visits. **FINANCIAL REVENUE & REVENUE ANALYTICS ARE STRICTLY HIDDEN.** |
