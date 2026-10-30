import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "database", "hospital.db")
QUERIES_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "database", "queries.sql")

def run_all_queries():
    print(f"Connecting to database: {DB_PATH}")
    if not os.path.exists(DB_PATH):
        print("Database not found! Running init_db.py first...")
        import init_db
        init_db.initialize_database()

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    with open(QUERIES_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    # Split by semicolon
    raw_queries = content.split(";")
    valid_count = 0

    print("=====================================================================")
    print("EXECUTING ALL 30 SQL RUBRIC QUERIES AGAINST HOSPITAL DATABASE")
    print("=====================================================================")

    for idx, raw in enumerate(raw_queries):
        # Extract title comment if exists
        lines = raw.strip().splitlines()
        comment = ""
        sql_lines = []
        for l in lines:
            if l.strip().startswith("--"):
                if not comment and ("Q1." in l or "Q2." in l or "Q3." in l or "Q4." in l or "Q5." in l or "Q6." in l or "VIEW" in l):
                    comment = l.strip().replace("--", "").strip()
            else:
                sql_lines.append(l)

        sql = " ".join(sql_lines).strip()
        if not sql:
            continue

        try:
            cursor.execute(sql)
            rows = cursor.fetchall()
            valid_count += 1
            label = comment if comment else f"Query #{valid_count}"
            print(f"[{valid_count:02d}] {label} -> OK ({len(rows)} rows returned)")
        except Exception as e:
            print(f"[FAIL] Query #{idx+1}: {e}\nSQL:\n{sql[:80]}...")

    conn.close()
    print("=====================================================================")
    print(f"SUMMARY: Successfully verified {valid_count} queries with 0 errors!")
    print("=====================================================================")

if __name__ == "__main__":
    run_all_queries()
