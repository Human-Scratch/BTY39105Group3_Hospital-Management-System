#!/bin/bash
echo "========================================================="
echo "Kolkata City Hospital & Medical Research Centre (KCHMRC)"
echo "Group 3 - Database Management System Lab (BTY39105)"
echo "Backend: Python Flask + MySQL Server 8.0 / SQLite Engine"
echo "========================================================="

# 1. Activate virtual environment if present
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# 2. Check if MySQL initialization is requested
if [ "$1" == "--init-mysql" ]; then
    echo "Running MySQL Provisioning Wizard..."
    python3 database/setup_mysql.py
fi

# 3. Start Flask Web Server
echo "Starting Hospital Portal on http://127.0.0.1:5000..."
python3 src/backend/app.py
