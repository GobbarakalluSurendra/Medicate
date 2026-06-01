from flask import request, jsonify
from app.models.appointment import Appointment
from app.models.hospital import Hospital
from app.models.doctor import Doctor
from app.models.patient import Patient
from app.models.prescription import Prescription

def patient_view_hospitals(current_user):
    """Allows patient to view all hospitals registered in the database."""
    hospitals = Hospital.get_all()
    return jsonify(hospitals), 200

def patient_view_hospital_doctors(current_user, hosp_id):
    """Allows patient to select a hospital and retrieve its doctors."""
    doctors = Doctor.get_by_hospital(hosp_id)
    return jsonify(doctors), 200

def patient_book_appointment(current_user):
    """Allows patient to book an appointment with a doctor at a hospital."""
    patient_id = current_user['id']
    data = request.get_json() or {}
    doctor_id = data.get('doctor_id')
    hospital_id = data.get('hospital_id')
    date = data.get('date')
    time = data.get('time')
    symptoms = data.get('symptoms')
    slot_id = data.get('slot_id') # Optional slot_id selection

    if not all([doctor_id, hospital_id, date, time]):
        return jsonify({'message': 'doctor_id, hospital_id, date, and time are required fields.'}), 400

    try:
        app_id = Appointment.create(patient_id, doctor_id, hospital_id, date, time, symptoms, slot_id)
        return jsonify({
            'message': 'Appointment booked successfully.',
            'appointment_id': app_id
        }), 201
    except Exception as e:
        return jsonify({'message': f'Failed to book appointment: {str(e)}'}), 500

def patient_view_appointments(current_user):
    """Allows patients to view their entire appointment list and booking status."""
    patient_id = current_user['id']
    appointments = Appointment.get_by_patient(patient_id)
    return jsonify(appointments), 200

def doctor_view_appointments(current_user):
    """Allows doctors to view their scheduled appointments."""
    doctor_id = current_user['id']
    appointments = Appointment.get_by_doctor(doctor_id)
    return jsonify(appointments), 200

def doctor_view_patient_details(current_user, patient_id):
    """Allows doctors to lookup details about a patient assigned to them."""
    patient = Patient.find_by_id(patient_id)
    if not patient:
        return jsonify({'message': 'Patient record not found.'}), 404
    # Security: Remove the sensitive password hash before transmitting
    patient.pop('password_hash', None)
    return jsonify(patient), 200

def admin_view_appointments(current_user):
    """Allows hospital admins to view all appointments booked under their hospital."""
    hospital_id = current_user['id']
    appointments = Appointment.get_by_hospital(hospital_id)
    return jsonify(appointments), 200

def patient_get_doctor_slots(current_user, doctor_id):
    """Allows a patient to retrieve all active unbooked slots for a doctor."""
    slots = Doctor.get_available_slots(doctor_id)
    return jsonify(slots), 200

def doctor_view_patient_history(current_user, patient_id):
    """Allows a doctor to retrieve the complete medical history (previous prescriptions) for a patient."""
    history = Prescription.get_by_patient(patient_id)
    return jsonify(history), 200
