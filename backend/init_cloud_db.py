import os
import sys
from dotenv import load_dotenv
import pymysql
import pymysql.cursors

# Load .env
load_dotenv()

DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_USER = os.environ.get('DB_USER', 'root')
DB_PASSWORD = os.environ.get('DB_PASSWORD', '')
DB_NAME = os.environ.get('DB_NAME', 'telemedicine_db')
DB_PORT = int(os.environ.get('DB_PORT', 3306))
DB_SSL = os.environ.get('DB_SSL', 'false').lower() in ('true', '1', 't')

def run_schema():
    print("=" * 60)
    print("  CLOUD DATABASE SCHEMA INITIALIZER")
    print("=" * 60)
    print(f"Target Host: {DB_HOST}")
    print(f"Target Port: {DB_PORT}")
    print(f"Target User: {DB_USER}")
    print(f"Target Database: {DB_NAME}")
    print(f"SSL Enabled: {DB_SSL}")
    print("-" * 60)

    ssl_config = {} if DB_SSL else None
    
    # 1. Check or Create the Database (Only if host allows database creation)
    try:
        print("[1/2] Connecting to server to verify database presence...")
        conn = pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            port=DB_PORT,
            ssl=ssl_config
        )
        with conn.cursor() as cursor:
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME}")
        conn.commit()
        conn.close()
        print(f"Database '{DB_NAME}' verified/created.")
    except Exception as e:
        print(f"Note: Could not run CREATE DATABASE command directly: {e}")
        print("This is normal on shared cloud hosting (e.g. Clever Cloud) where databases are pre-allocated.")
        print("Proceeding to execute tables schema inside the pre-allocated database...")

    # 2. Run schema.sql
    schema_path = os.path.join(os.path.dirname(__file__), 'schema.sql')
    if not os.path.exists(schema_path):
        print(f"Error: schema.sql not found at {schema_path}")
        sys.exit(1)

    print("\n[2/2] Connecting directly to database to create tables...")
    try:
        conn = pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            port=DB_PORT,
            cursorclass=pymysql.cursors.DictCursor,
            ssl=ssl_config
        )
    except Exception as e:
        print(f"Failed to connect to database: {e}")
        print("\nPlease check that your .env connection details are correct and your network allows access.")
        sys.exit(1)

    try:
        with open(schema_path, 'r') as f:
            sql_commands = f.read().split(';')

        with conn.cursor() as cursor:
            for cmd in sql_commands:
                cmd_stripped = cmd.strip()
                if cmd_stripped:
                    # Skip database creation/switching commands as we are already connected to target database
                    if cmd_stripped.upper().startswith("USE "):
                        continue
                    if cmd_stripped.upper().startswith("CREATE DATABASE "):
                        continue
                    
                    print(f"Running query: {cmd_stripped.splitlines()[0][:60]}...")
                    cursor.execute(cmd_stripped)
        conn.commit()
        print("\nSUCCESS: All schema tables loaded successfully into your cloud database!")
    except Exception as e:
        print(f"\nError running schema SQL commands: {e}")
    finally:
        conn.close()
    print("=" * 60)

if __name__ == '__main__':
    run_schema()
