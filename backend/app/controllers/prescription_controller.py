from flask import request, jsonify, send_file
from app.models.prescription import Prescription
from app.models.appointment import Appointment
from app.utils.pdf_generator import generate_prescription_pdf

def doctor_create_prescription(current_user):
    """Allows doctors to document a prescription and updates the appointment status to completed."""
    doctor_id = current_user['id']
    data = request.get_json() or {}
    appointment_id = data.get('appointment_id')
    diagnosis = data.get('diagnosis')
    medicines = data.get('medicines')
    instructions = data.get('instructions')
    follow_up_date = data.get('follow_up_date') # Optional follow-up date

    if not all([appointment_id, diagnosis, medicines]):
        return jsonify({'message': 'appointment_id, diagnosis, and medicines are required.'}), 400

    # Retrieve appointment details to verify doctor and patient ID
    appointment = Appointment.find_by_id(appointment_id)
    if not appointment:
        return jsonify({'message': 'Appointment record not found.'}), 404
        
    if str(appointment['doctor_id']) != str(doctor_id):
        return jsonify({'message': 'Access denied: You are not the doctor assigned to this appointment.'}), 403

    try:
        # Create prescription record
        Prescription.create(
            appointment_id=appointment_id,
            patient_id=appointment['patient_id'],
            doctor_id=doctor_id,
            diagnosis=diagnosis,
            medicines=medicines,
            instructions=instructions,
            follow_up_date=follow_up_date
        )
        
        # Auto-update appointment status to completed
        Appointment.update_status(appointment_id, 'completed')
        
        return jsonify({'message': 'Prescription saved and appointment completed.'}), 201
    except Exception as e:
        return jsonify({'message': f'Failed to create prescription: {str(e)}'}), 500

def doctor_view_prescription_history(current_user):
    """Retrieves list of all prescriptions authored by this doctor."""
    doctor_id = current_user['id']
    history = Prescription.get_by_doctor(doctor_id)
    return jsonify(history), 200

def patient_view_prescription_history(current_user):
    """Retrieves list of all prescriptions written for this patient."""
    patient_id = current_user['id']
    history = Prescription.get_by_patient(patient_id)
    return jsonify(history), 200

def download_prescription_pdf(current_user, presc_id):
    """Generates and downloads a custom ReportLab PDF for the prescription."""
    prescription = Prescription.find_by_id(presc_id)
    if not prescription:
        return jsonify({'message': 'Prescription record not found.'}), 404
        
    # Security: Ensure only the prescription's patient or writer doctor can download
    is_patient_owner = (current_user['role'] == 'patient' and str(prescription['patient_id']) == str(current_user['id']))
    is_doctor_writer = (current_user['role'] == 'doctor' and str(prescription['doctor_id']) == str(current_user['id']))
    
    if not (is_patient_owner or is_doctor_writer):
        return jsonify({'message': 'Access denied: You do not have permission to download this prescription.'}), 403

    try:
        pdf_buffer = generate_prescription_pdf(prescription)
        return send_file(
            pdf_buffer,
            mimetype='application/pdf',
            as_attachment=True,
            download_name=f"Prescription_{presc_id}.pdf"
        )
    except Exception as e:
        return jsonify({'message': f'Failed to generate PDF download stream: {str(e)}'}), 500
