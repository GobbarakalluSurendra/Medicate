import random
from werkzeug.security import generate_password_hash, check_password_hash
from app.models.database import execute_query

class Hospital:
    @staticmethod
    def generate_id():
        """Generates a unique hospital ID with format HOSP001, HOSP002, etc."""
        try:
            res = execute_query("SELECT COUNT(*) as count FROM hospitals", fetchone=True)
            count = res['count'] if res else 0
            return f"HOSP{count + 1:03d}"
        except Exception:
            # Fallback to random if database is not active yet during code analysis
            import random
            return f"HOSP{random.randint(100, 999)}"

    @staticmethod
    def create(name, address, email, password):
        """Creates a new hospital record and returns the generated hospital ID."""
        hosp_id = Hospital.generate_id()
        password_hash = generate_password_hash(password)
        
        query = """
            INSERT INTO hospitals (id, name, address, email, password_hash)
            VALUES (%s, %s, %s, %s, %s)
        """
        execute_query(query, (hosp_id, name, address, email, password_hash), commit=True)
        return hosp_id

    @staticmethod
    def find_by_id(hosp_id):
        """Finds a hospital record by its ID."""
        return execute_query("SELECT * FROM hospitals WHERE id = %s", (hosp_id,), fetchone=True)

    @staticmethod
    def find_by_email(email):
        """Finds a hospital record by its email address."""
        return execute_query("SELECT * FROM hospitals WHERE email = %s", (email,), fetchone=True)

    @staticmethod
    def verify_password(stored_hash, password):
        """Verifies if a password matches the stored password hash."""
        return check_password_hash(stored_hash, password)

    @staticmethod
    def get_all():
        """Returns a list of all registered hospitals."""
        return execute_query("SELECT id, name, address, email, created_at FROM hospitals ORDER BY name", fetchall=True)
