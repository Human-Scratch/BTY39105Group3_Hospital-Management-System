import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "database", "hospital.db")
SCHEMA_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "database", "schema.sql")
INSERT_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "database", "insert_data.sql")
VIEWS_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "database", "views.sql")
TRIGGERS_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "database", "triggers.sql")

def initialize_database():
    print(f"Initializing database at: {DB_PATH}")
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
        
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # 1. Execute schema
    print("Executing schema.sql...")
    with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
        cursor.executescript(f.read())
        
    # 2. Execute insert_data
    print("Executing insert_data.sql...")
    with open(INSERT_PATH, "r", encoding="utf-8") as f:
        cursor.executescript(f.read())
        
    # 3. Execute views
    print("Executing views.sql...")
    with open(VIEWS_PATH, "r", encoding="utf-8") as f:
        cursor.executescript(f.read())
        
    # 4. Execute triggers
    print("Executing triggers.sql...")
    with open(TRIGGERS_PATH, "r", encoding="utf-8") as f:
        # filter out MySQL comment blocks
        lines = f.readlines()
        clean_lines = []
        in_block = False
        for l in lines:
            if "/*" in l:
                in_block = True
            if not in_block:
                clean_lines.append(l)
            if "*/" in l:
                in_block = False
        cursor.executescript("".join(clean_lines))
        
    conn.commit()
    conn.close()
    print("Database initialization completed successfully with 270+ records and triggers!")

if __name__ == "__main__":
    initialize_database()
