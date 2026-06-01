import os
import pymysql
import pymysql.cursors
from app.config import Config

def get_db_connection():
    """Establishes and returns a connection to the MySQL database."""
    ssl_config = {} if Config.DB_SSL else None
    return pymysql.connect(
        host=Config.DB_HOST,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        database=Config.DB_NAME,
        port=Config.DB_PORT,
        cursorclass=pymysql.cursors.DictCursor,
        ssl=ssl_config
    )

def init_db(schema_path=None):
    """Initializes the database by creating it if needed and running schema.sql."""
    # Connect without a default database first to create the database if it doesn't exist
    ssl_config = {} if Config.DB_SSL else None
    conn = pymysql.connect(
        host=Config.DB_HOST,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        port=Config.DB_PORT,
        ssl=ssl_config
    )
    try:
        with conn.cursor() as cursor:
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS {Config.DB_NAME}")
        conn.commit()
    except Exception as e:
        print(f"Error creating database: {e}")
    finally:
        conn.close()


    # Locate schema.sql file path
    if not schema_path:
        schema_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'schema.sql')

    if os.path.exists(schema_path):
        print(f"Executing database schema from {schema_path}...")
        with open(schema_path, 'r') as f:
            # Split schema commands by semicolon
            sql_commands = f.read().split(';')
        
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                for cmd in sql_commands:
                    cmd_stripped = cmd.strip()
                    if cmd_stripped:
                        # PyMySQL doesn't run multiple commands in one execute, so run sequentially
                        cursor.execute(cmd_stripped)
            conn.commit()
            print("Database schema loaded successfully.")
        except Exception as e:
            print(f"Error loading schema: {e}")
        finally:
            conn.close()
    else:
        print(f"Schema file not found at {schema_path}, skipping schema execution.")

def execute_query(query, args=(), fetchall=False, fetchone=False, commit=False):
    """Utility function to execute parameterized SQL statements safely."""
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, args)
            if commit:
                conn.commit()
                # If doing an insert, return the last inserted ID, else return rowcount
                return cursor.lastrowid if cursor.lastrowid != 0 else cursor.rowcount
            if fetchall:
                return cursor.fetchall()
            if fetchone:
                return cursor.fetchone()
    except Exception as e:
        print(f"Database error during query '{query}': {e}")
        raise e
    finally:
        conn.close()
