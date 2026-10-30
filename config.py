import os

class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "kchmrc_kolkata_super_secret_jwt_replacement_key_2026")
    
    # MySQL Database Connection Settings
    MYSQL_HOST = os.getenv("MYSQL_HOST", "localhost")
    MYSQL_PORT = int(os.getenv("MYSQL_PORT", 3306))
    MYSQL_USER = os.getenv("MYSQL_USER", "root")
    MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "")
    MYSQL_DB = os.getenv("MYSQL_DB", "kolkata_hospital_db")
    
    # Fallback SQLite Path
    SQLITE_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "database", "hospital.db")
