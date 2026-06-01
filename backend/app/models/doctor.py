import random
from werkzeug.security import generate_password_hash, check_password_hash
from app.models.database import execute_query

class Doctor:
    @staticmethod
    def generate_id():
        """Generates a unique doctor ID with format DOC001, DOC002, etc."""
        try:
            res = execute_query("SELECT COUNT(*) as count FROM doctors", fetchone=True)
            count = res['count'] if res else 0
            return f"DOC{count + 1:03d}"
        except Exception:
            return f"DOC{random.randint(100, 999)}"

    @staticmethod
    def create(name, specialization, qualification, experience, phone, email, password):
        """Creates a new doctor and returns the generated doctor ID."""
        doc_id = Doctor.generate_id()
        password_hash = generate_password_hash(password)
        
        query = """
            INSERT INTO doctors (id, name, specialization, qualification, experience, phone, email, password_hash)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        execute_query(query, (doc_id, name, specialization, qualification, int(experience), phone, email, password_hash), commit=True)
        return doc_id

    @staticmethod
    def find_by_id(doc_id):
        """Finds a doctor record by its ID."""
        return execute_query("SELECT * FROM doctors WHERE id = %s", (doc_id,), fetchone=True)

    @staticmethod
    def find_by_email(email):
        """Finds a doctor record by its email address."""
        return execute_query("SELECT * FROM doctors WHERE email = %s", (email,), fetchone=True)

    @staticmethod
    def verify_password(stored_hash, password):
        """Verifies if a password matches the stored password hash."""
        return check_password_hash(stored_hash, password)

    @staticmethod
    def add_to_hospital(doc_id, hospital_id):
        """Associates a doctor with a hospital."""
        query = "UPDATE doctors SET hospital_id = %s WHERE id = %s"
        return execute_query(query, (hospital_id, doc_id), commit=True)

    @staticmethod
    def get_by_hospital(hospital_id):
        """Retrieves all doctors associated with a hospital."""
        query = """
            SELECT id, name, specialization, qualification, experience, phone, email, hospital_id 
            FROM doctors 
            WHERE hospital_id = %s 
            ORDER BY name ASC
        """
        return execute_query(query, (hospital_id,), fetchall=True)

    @staticmethod
    def get_all():
        """Retrieves all doctors registered in the system."""
        query = "SELECT id, name, specialization, qualification, experience, phone, email, hospital_id FROM doctors ORDER BY name ASC"
        return execute_query(query, fetchall=True)

    # ==========================================
    # DOCTOR AVAILABILITY SLOTS MANAGEMENT
    # ==========================================
    @staticmethod
    def add_availability_slot(doctor_id, slot_date, slot_time):
        """Adds a new time slot of availability for a doctor."""
        query = """
            INSERT INTO doctor_availability (doctor_id, slot_date, slot_time, is_booked)
            VALUES (%s, %s, %s, FALSE)
        """
        return execute_query(query, (doctor_id, slot_date, slot_time), commit=True)

    @staticmethod
    def get_available_slots(doctor_id):
        """Retrieves all unbooked time slots for a doctor."""
        query = """
            SELECT id, slot_date, slot_time, is_booked 
            FROM doctor_availability 
            WHERE doctor_id = %s AND is_booked = FALSE
            ORDER BY slot_date ASC, slot_time ASC
        """
        # Convert date and time objects to strings for clean JSON serialization
        slots = execute_query(query, (doctor_id,), fetchall=True)
        for s in slots:
            if 'slot_date' in s:
                s['slot_date'] = str(s['slot_date'])
            if 'slot_time' in s:
                s['slot_time'] = str(s['slot_time'])
        return slots

    @staticmethod
    def get_all_slots(doctor_id):
        """Retrieves all slots (both booked and unbooked) for a doctor."""
        query = """
            SELECT id, slot_date, slot_time, is_booked 
            FROM doctor_availability 
            WHERE doctor_id = %s
            ORDER BY slot_date ASC, slot_time ASC
        """
        slots = execute_query(query, (doctor_id,), fetchall=True)
        for s in slots:
            if 'slot_date' in s:
                s['slot_date'] = str(s['slot_date'])
            if 'slot_time' in s:
                s['slot_time'] = str(s['slot_time'])
        return slots

    @staticmethod
    def book_slot(slot_id):
        """Marks an availability slot as booked."""
        query = "UPDATE doctor_availability SET is_booked = TRUE WHERE id = %s"
        return execute_query(query, (slot_id,), commit=True)
