from app.models.database import execute_query

class Prescription:
    @staticmethod
    def create(appointment_id, patient_id, doctor_id, diagnosis, medicines, instructions=None, follow_up_date=None):
        """Saves a prescription to the database with optional follow-up date."""
        query = """
            INSERT INTO prescriptions (appointment_id, patient_id, doctor_id, diagnosis, medicines, instructions, follow_up_date)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        return execute_query(query, (appointment_id, patient_id, doctor_id, diagnosis, medicines, instructions, follow_up_date), commit=True)

    @staticmethod
    def find_by_id(presc_id):
        """Finds a detailed prescription record by ID, mapping doctor, patient, and hospital information."""
        query = """
            SELECT pr.id, pr.appointment_id, pr.patient_id, pr.doctor_id, pr.diagnosis, pr.medicines, pr.instructions, pr.follow_up_date, pr.created_at,
                   p.name AS patient_name, p.email AS patient_email, p.phone AS patient_phone,
                   d.name AS doctor_name, d.specialization AS doctor_specialization, d.phone AS doctor_phone,
                   h.name AS hospital_name, h.address AS hospital_address
            FROM prescriptions pr
            INNER JOIN patients p ON pr.patient_id = p.id
            INNER JOIN doctors d ON pr.doctor_id = d.id
            INNER JOIN appointments a ON pr.appointment_id = a.id
            INNER JOIN hospitals h ON a.hospital_id = h.id
            WHERE pr.id = %s
        """
        res = execute_query(query, (presc_id,), fetchone=True)
        if res and 'follow_up_date' in res and res['follow_up_date']:
            res['follow_up_date'] = str(res['follow_up_date'])
        return res

    @staticmethod
    def get_by_doctor(doctor_id):
        """Retrieves all prescriptions written by a doctor."""
        query = """
            SELECT pr.id, pr.appointment_id, pr.diagnosis, pr.medicines, pr.instructions, pr.follow_up_date, pr.created_at,
                   p.name AS patient_name
            FROM prescriptions pr
            INNER JOIN patients p ON pr.patient_id = p.id
            WHERE pr.doctor_id = %s
            ORDER BY pr.created_at DESC
        """
        records = execute_query(query, (doctor_id,), fetchall=True)
        for r in records:
            if 'follow_up_date' in r and r['follow_up_date']:
                r['follow_up_date'] = str(r['follow_up_date'])
            if 'created_at' in r and r['created_at']:
                r['created_at'] = str(r['created_at'])
        return records

    @staticmethod
    def get_by_patient(patient_id):
        """Retrieves all prescriptions written for a patient (Medical History)."""
        query = """
            SELECT pr.id, pr.appointment_id, pr.diagnosis, pr.medicines, pr.instructions, pr.follow_up_date, pr.created_at,
                   d.name AS doctor_name, d.specialization AS doctor_specialization,
                   h.name AS hospital_name
            FROM prescriptions pr
            INNER JOIN doctors d ON pr.doctor_id = d.id
            INNER JOIN appointments a ON pr.appointment_id = a.id
            INNER JOIN hospitals h ON a.hospital_id = h.id
            WHERE pr.patient_id = %s
            ORDER BY pr.created_at DESC
        """
        records = execute_query(query, (patient_id,), fetchall=True)
        for r in records:
            if 'follow_up_date' in r and r['follow_up_date']:
                r['follow_up_date'] = str(r['follow_up_date'])
            if 'created_at' in r and r['created_at']:
                r['created_at'] = str(r['created_at'])
        return records
