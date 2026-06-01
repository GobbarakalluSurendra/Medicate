from app.models.database import execute_query

class Appointment:
    @staticmethod
    def create(patient_id, doctor_id, hospital_id, appointment_date, appointment_time, symptoms=None, slot_id=None):
        """Creates a new appointment booking and flags the corresponding slot as booked."""
        # Flag the slot as booked
        if slot_id:
            from app.models.doctor import Doctor
            Doctor.book_slot(slot_id)
        else:
            # Try to auto-match slot in database and mark booked
            from app.models.doctor import Doctor
            try:
                # Find unbooked slot matching date, time, and doctor
                find_query = """
                    SELECT id FROM doctor_availability 
                    WHERE doctor_id = %s AND slot_date = %s AND slot_time = %s AND is_booked = FALSE
                    LIMIT 1
                """
                slot = execute_query(find_query, (doctor_id, appointment_date, appointment_time), fetchone=True)
                if slot:
                    Doctor.book_slot(slot['id'])
            except Exception as e:
                print(f"[SLOT LINK WARNING] Could not auto-book slot: {e}")

        query = """
            INSERT INTO appointments (patient_id, doctor_id, hospital_id, appointment_date, appointment_time, symptoms, status)
            VALUES (%s, %s, %s, %s, %s, %s, 'booked')
        """
        return execute_query(query, (patient_id, doctor_id, hospital_id, appointment_date, appointment_time, symptoms), commit=True)

    @staticmethod
    def _format_appointment(app):
        if not app:
            return app
        if 'appointment_date' in app and app['appointment_date']:
            app['appointment_date'] = str(app['appointment_date'])
        if 'appointment_time' in app and app['appointment_time']:
            app['appointment_time'] = str(app['appointment_time'])
        if 'created_at' in app and app['created_at']:
            app['created_at'] = str(app['created_at'])
        return app

    @staticmethod
    def find_by_id(app_id):
        """Finds an appointment and joins doctor, patient, and hospital data."""
        query = """
            SELECT a.id, a.patient_id, a.doctor_id, a.hospital_id, a.appointment_date, a.appointment_time, a.status, a.symptoms, a.created_at,
                   p.name AS patient_name, p.email AS patient_email, p.phone AS patient_phone, 
                   d.name AS doctor_name, d.specialization AS doctor_specialization,
                   h.name AS hospital_name
            FROM appointments a
            INNER JOIN patients p ON a.patient_id = p.id
            INNER JOIN doctors d ON a.doctor_id = d.id
            INNER JOIN hospitals h ON a.hospital_id = h.id
            WHERE a.id = %s
        """
        res = execute_query(query, (app_id,), fetchone=True)
        return Appointment._format_appointment(res)

    @staticmethod
    def get_by_patient(patient_id):
        """Gets all appointments booked by a patient."""
        query = """
            SELECT a.id, a.appointment_date, a.appointment_time, a.status, a.symptoms, a.created_at,
                   d.name AS doctor_name, d.specialization AS doctor_specialization,
                   h.name AS hospital_name, h.address AS hospital_address
            FROM appointments a
            INNER JOIN doctors d ON a.doctor_id = d.id
            INNER JOIN hospitals h ON a.hospital_id = h.id
            WHERE a.patient_id = %s
            ORDER BY a.appointment_date DESC, a.appointment_time DESC
        """
        res = execute_query(query, (patient_id,), fetchall=True)
        return [Appointment._format_appointment(r) for r in res]

    @staticmethod
    def get_by_doctor(doctor_id):
        """Gets all appointments booked with a doctor."""
        query = """
            SELECT a.id, a.appointment_date, a.appointment_time, a.status, a.symptoms, a.created_at,
                   p.id AS patient_id, p.name AS patient_name, p.email AS patient_email, p.phone AS patient_phone
            FROM appointments a
            INNER JOIN patients p ON a.patient_id = p.id
            WHERE a.doctor_id = %s
            ORDER BY a.appointment_date DESC, a.appointment_time DESC
        """
        res = execute_query(query, (doctor_id,), fetchall=True)
        return [Appointment._format_appointment(r) for r in res]

    @staticmethod
    def get_by_hospital(hospital_id):
        """Gets all appointments booked for a hospital."""
        query = """
            SELECT a.id, a.appointment_date, a.appointment_time, a.status, a.symptoms, a.created_at,
                   p.name AS patient_name, d.name AS doctor_name, d.specialization AS doctor_specialization
            FROM appointments a
            INNER JOIN patients p ON a.patient_id = p.id
            INNER JOIN doctors d ON a.doctor_id = d.id
            WHERE a.hospital_id = %s
            ORDER BY a.appointment_date DESC, a.appointment_time DESC
        """
        res = execute_query(query, (hospital_id,), fetchall=True)
        return [Appointment._format_appointment(r) for r in res]

    @staticmethod
    def update_status(app_id, status):
        """Updates the status of an appointment (e.g. 'completed', 'cancelled')."""
        query = "UPDATE appointments SET status = %s WHERE id = %s"
        return execute_query(query, (status, app_id), commit=True)
