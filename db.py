import os
import sqlite3
from config import Config

# Check for pymysql or mysql.connector
MYSQL_DRIVER = None
try:
    import pymysql
    import pymysql.cursors
    MYSQL_DRIVER = "pymysql"
except ImportError:
    try:
        import mysql.connector
        MYSQL_DRIVER = "mysql.connector"
    except ImportError:
        MYSQL_DRIVER = None

class Database:
    @staticmethod
    def get_connection():
        """
        Returns an active database connection.
        Prioritizes MySQL Server if driver and database are reachable;
        gracefully falls back to local SQLite database if MySQL is unavailable.
        """
        if MYSQL_DRIVER == "pymysql":
            try:
                conn = pymysql.connect(
                    host=Config.MYSQL_HOST,
                    port=Config.MYSQL_PORT,
                    user=Config.MYSQL_USER,
                    password=Config.MYSQL_PASSWORD,
                    database=Config.MYSQL_DB,
                    cursorclass=pymysql.cursors.DictCursor,
                    autocommit=False
                )
                return conn, "mysql"
            except Exception as e:
                # Fallback to SQLite if MySQL server is offline
                pass
        elif MYSQL_DRIVER == "mysql.connector":
            try:
                conn = mysql.connector.connect(
                    host=Config.MYSQL_HOST,
                    port=Config.MYSQL_PORT,
                    user=Config.MYSQL_USER,
                    password=Config.MYSQL_PASSWORD,
                    database=Config.MYSQL_DB
                )
                return conn, "mysql"
            except Exception as e:
                pass

        # SQLite Connection Fallback
        conn = sqlite3.connect(Config.SQLITE_PATH)
        conn.row_factory = sqlite3.Row
        return conn, "sqlite"

    @staticmethod
    def query(sql, params=None, fetchone=False):
        """Executes a SELECT query and returns rows as dictionaries."""
        conn, engine = Database.get_connection()
        params = params or ()
        
        # Translate placeholder syntax if necessary (%s for MySQL, ? for SQLite)
        if engine == "sqlite":
            sql_adapted = sql.replace("%s", "?")
            cursor = conn.cursor()
            cursor.execute(sql_adapted, params)
            if fetchone:
                row = cursor.fetchone()
                result = dict(row) if row else None
            else:
                result = [dict(r) for r in cursor.fetchall()]
            conn.close()
            return result
        else:
            # MySQL Execution
            with conn.cursor() as cursor:
                cursor.execute(sql, params)
                result = cursor.fetchone() if fetchone else cursor.fetchall()
            conn.close()
            return result

    @staticmethod
    def execute(sql, params=None):
        """Executes an INSERT/UPDATE/DELETE statement within a transaction."""
        conn, engine = Database.get_connection()
        params = params or ()
        try:
            if engine == "sqlite":
                sql_adapted = sql.replace("%s", "?")
                cursor = conn.cursor()
                cursor.execute(sql_adapted, params)
                conn.commit()
                last_id = cursor.lastrowid
                conn.close()
                return last_id
            else:
                with conn.cursor() as cursor:
                    cursor.execute(sql, params)
                    last_id = cursor.lastrowid
                conn.commit()
                conn.close()
                return last_id
        except Exception as e:
            conn.rollback()
            conn.close()
            raise e
