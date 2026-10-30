@echo off
echo =========================================================
echo Kolkata City Hospital & Medical Research Centre (KCHMRC)
echo Group 3 - Database Management System Lab (BTY39105)
echo Backend: Python Flask + MySQL Server 8.0 / SQLite Engine
echo =========================================================

if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate.bat
)

if "%1"=="--init-mysql" (
    echo Running MySQL Provisioning Wizard...
    python database\setup_mysql.py
)

echo Starting Hospital Portal on http://127.0.0.1:5000...
python src\backend\app.py
pause
