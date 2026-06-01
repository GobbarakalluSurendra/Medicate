from flask import request, jsonify
from app.models.doctor import Doctor
from app.models.patient import Patient

def admin_add_doctor(current_user):
    """
    Allows a logged-in hospital admin to add a registered doctor
    to their hospital database using the doctor's unique Doctor ID.
    """
    data = request.get_json() or {}
    doctor_id = data.get('doctor_id')
    
    if not doctor_id:
        return jsonify({'message': 'Doctor ID is required.'}), 400
        
    doctor = Doctor.find_by_id(doctor_id)
    if not doctor:
        return jsonify({'message': 'Doctor with the provided ID does not exist.'}), 404
        
    hospital_id = current_user['id']
    
    try:
        Doctor.add_to_hospital(doctor_id, hospital_id)
        return jsonify({'message': 'Doctor associated with hospital successfully.'}), 200
    except Exception as e:
        return jsonify({'message': f'Failed to associate doctor: {str(e)}'}), 500

def admin_view_doctors(current_user):
    """Lists all doctors linked to the calling hospital admin."""
    hospital_id = current_user['id']
    doctors = Doctor.get_by_hospital(hospital_id)
    return jsonify(doctors), 200

def admin_view_patients(current_user):
    """Lists all distinct patients who have scheduled appointments at the calling hospital."""
    hospital_id = current_user['id']
    patients = Patient.get_by_hospital(hospital_id)
    return jsonify(patients), 200

def doctor_add_slot(current_user):
    """Allows a logged-in doctor to add an availability time slot."""
    data = request.get_json() or {}
    slot_date = data.get('date')
    slot_time = data.get('time')
    
    if not slot_date or not slot_time:
        return jsonify({'message': 'Date and time are required fields.'}), 400
        
    try:
        Doctor.add_availability_slot(current_user['id'], slot_date, slot_time)
        return jsonify({'message': 'Availability slot added successfully.'}), 201
    except Exception as e:
        return jsonify({'message': f'Failed to add availability slot: {str(e)}'}), 500

def doctor_get_own_slots(current_user):
    """Allows a logged-in doctor to retrieve their own slots registry."""
    slots = Doctor.get_all_slots(current_user['id'])
    return jsonify(slots), 200
