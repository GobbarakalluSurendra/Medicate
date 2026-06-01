from werkzeug.security import generate_password_hash, check_password_hash
from app.models.database import execute_query

class Patient:
    @staticmethod
    def create(name, email, password, phone, is_verified=True):
        """Creates a new patient profile. Password is automatically hashed."""
        password_hash = generate_password_hash(password)
        query = """
            INSERT INTO patients (name, email, password_hash, phone, is_verified)
            VALUES (%s, %s, %s, %s, %s)
        """
        patient_id = execute_query(query, (name, email, password_hash, phone, is_verified), commit=True)
        return patient_id

    @staticmethod
    def find_by_id(patient_id):
        """Finds a patient record by ID."""
        return execute_query("SELECT * FROM patients WHERE id = %s", (patient_id,), fetchone=True)

    @staticmethod
    def find_by_email(email):
        """Finds a patient record by email address."""
        return execute_query("SELECT * FROM patients WHERE email = %s", (email,), fetchone=True)

    @staticmethod
    def verify_password(stored_hash, password):
        """Verifies if a password matches the stored password hash."""
        return check_password_hash(stored_hash, password)

    @staticmethod
    def get_by_hospital(hospital_id):
        """Retrieves all unique patients who have booked appointments at this hospital."""
        query = """
            SELECT DISTINCT p.id, p.name, p.email, p.phone, p.created_at
            FROM patients p
            INNER JOIN appointments a ON p.id = a.patient_id
            WHERE a.hospital_id = %s
            ORDER BY p.name ASC
        """
        return execute_query(query, (hospital_id,), fetchall=True)
