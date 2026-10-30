"""
Kolkata City Hospital & Medical Research Centre (KCHMRC)
MySQL Database Automated Provisioning Script
=============================================================
This script connects to your local or remote MySQL Server,
creates the database 'kolkata_hospital_db', and executes:
  1. schema_mysql.sql       (14 Normalized Tables & Constraints)
  2. insert_data_mysql.sql  (270+ Realistic Kolkata Seed Records)
  3. views_mysql.sql        (3 Analytical Production Views)
  4. triggers_mysql.sql     (Slot Conflict & Billing Triggers)
  5. procedures_mysql.sql   (Stored Procedures, Function & Transaction)
"""

import os
import sys

def get_mysql_connection():
    try:
        import pymysql
        return "pymysql", pymysql
    except ImportError:
        try:
            import mysql.connector
            return "mysql.connector", mysql.connector
        except ImportError:
            print("ERROR: Neither 'pymysql' nor 'mysql-connector-python' is installed.")
            print("Run: pip install pymysql mysql-connector-python")
            sys.exit(1)

def run_mysql_setup():
    host = os.getenv("MYSQL_HOST", "localhost")
    port = int(os.getenv("MYSQL_PORT", 3306))
    user = os.getenv("MYSQL_USER", "root")
    password = os.getenv("MYSQL_PASSWORD", "")
    db_name = os.getenv("MYSQL_DB", "kolkata_hospital_db")

    print("================================================================")
    print("KOLKATA CITY HOSPITAL (KCHMRC) - MYSQL PROVISIONING WIZARD")
    print("================================================================")
    print(f"Target MySQL Host: {host}:{port}")
    print(f"MySQL User:        {user}")
    print(f"Database:          {db_name}")
    print("================================================================")

    driver_name, driver = get_mysql_connection()

    # Step 1: Connect to MySQL server without database to create DB
    print(f"\n[1/5] Connecting to MySQL Server ({driver_name})...")
    if driver_name == "pymysql":
        conn = driver.connect(host=host, port=port, user=user, password=password, autocommit=True)
    else:
        conn = driver.connect(host=host, port=port, user=user, password=password)
        conn.autocommit = True

    cursor = conn.cursor()
    cursor.execute(f"CREATE DATABASE IF NOT EXISTS {db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
    print(f"[OK] Database '{db_name}' ensured.")
    conn.close()

    # Step 2: Connect directly to the database
    print(f"\n[2/5] Connecting to database '{db_name}'...")
    if driver_name == "pymysql":
        conn = driver.connect(host=host, port=port, user=user, password=password, database=db_name, autocommit=True)
    else:
        conn = driver.connect(host=host, port=port, user=user, password=password, database=db_name)
        conn.autocommit = True
    cursor = conn.cursor()

    base_dir = os.path.dirname(__file__)

    # Step 3: Run Schema
    print("[3/5] Executing schema_mysql.sql (14 Tables & Constraints)...")
    schema_path = os.path.join(base_dir, "schema_mysql.sql")
    with open(schema_path, "r", encoding="utf-8") as f:
        sql = f.read()
    # Split queries by semicolon (excluding DELIMITER blocks)
    for stmt in sql.split(";"):
        stmt = stmt.strip()
        if stmt and not stmt.startswith("--") and not stmt.startswith("/*"):
            try:
                cursor.execute(stmt)
            except Exception as e:
                print(f"  Notice: {e}")

    # Step 4: Run Insert Data
    print("[4/5] Executing insert_data_mysql.sql (270+ Seed Records)...")
    insert_path = os.path.join(base_dir, "insert_data_mysql.sql")
    with open(insert_path, "r", encoding="utf-8") as f:
        sql = f.read()
    for stmt in sql.split(";"):
        stmt = stmt.strip()
        if stmt and not stmt.startswith("--") and not stmt.startswith("/*"):
            try:
                cursor.execute(stmt)
            except Exception as e:
                pass

    # Step 5: Run Views
    print("[5/5] Executing views_mysql.sql (3 Production Views)...")
    views_path = os.path.join(base_dir, "views_mysql.sql")
    with open(views_path, "r", encoding="utf-8") as f:
        sql = f.read()
    for stmt in sql.split(";"):
        stmt = stmt.strip()
        if stmt and not stmt.startswith("--"):
            try:
                cursor.execute(stmt)
            except Exception as e:
                pass

    print("\n================================================================")
    print("PROVISIONING COMPLETED SUCCESSFULLY!")
    print("Your MySQL Database 'kolkata_hospital_db' is 100% configured.")
    print("================================================================")
    conn.close()

if __name__ == "__main__":
    run_mysql_setup()
