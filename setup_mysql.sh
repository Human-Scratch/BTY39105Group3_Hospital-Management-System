#!/bin/bash
# Kolkata Hospital - MySQL CLI Setup Script
# Usage: ./setup_mysql.sh [root_user] [password]

USER=${1:-root}
echo "Enter MySQL password for user '$USER' (or press Enter if blank):"
read -s PASSWORD

CMD="mysql -u $USER"
if [ -n "$PASSWORD" ]; then
    CMD="mysql -u $USER -p$PASSWORD"
fi

echo "Creating database & tables..."
$CMD < database/schema_mysql.sql

echo "Loading 270+ sample records..."
$CMD < database/insert_data_mysql.sql

echo "Creating analytical views..."
$CMD < database/views_mysql.sql

echo "Creating triggers..."
$CMD < database/triggers_mysql.sql

echo "Creating stored procedures & functions..."
$CMD < database/procedures_mysql.sql

echo "MySQL Database kolkata_hospital_db initialized successfully!"
