@echo off
REM Kolkata Hospital - MySQL CLI Setup Script for Windows
set /p USER="Enter MySQL Username (default: root): "
if "%USER%"=="" set USER=root

set /p PASSWORD="Enter MySQL Password (press Enter if blank): "

set CMD=mysql -u %USER%
if not "%PASSWORD%"=="" set CMD=mysql -u %USER% -p%PASSWORD%

echo Creating database and tables...
%CMD% < database\schema_mysql.sql

echo Loading 270+ sample records...
%CMD% < database\insert_data_mysql.sql

echo Creating analytical views...
%CMD% < database\views_mysql.sql

echo Creating triggers...
%CMD% < database\triggers_mysql.sql

echo Creating stored procedures...
%CMD% < database\procedures_mysql.sql

echo MySQL Database kolkata_hospital_db initialized successfully!
pause
