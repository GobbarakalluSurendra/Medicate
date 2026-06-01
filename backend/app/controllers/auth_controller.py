from flask import request, jsonify
from app.models.hospital import Hospital
from app.models.doctor import Doctor
from app.models.patient import Patient
from app.utils.auth_middleware import generate_token
from app.utils.otp_service import generate_otp, verify_otp

def admin_register():
    data = request.get_json() or {}
    name = data.get('name')
    address = data.get('address')
    email = data.get('email')
    password = data.get('password')

    if not all([name, address, email, password]):
        return jsonify({'message': 'All fields (name, address, email, password) are required.'}), 400

    if Hospital.find_by_email(email):
        return jsonify({'message': 'A hospital with this email already exists.'}), 400

    try:
        hosp_id = Hospital.create(name, address, email, password)
        return jsonify({
            'message': 'Hospital registered successfully.',
            'hospital_id': hosp_id
        }), 201
    except Exception as e:
        return jsonify({'message': f'Registration failed: {str(e)}'}), 500

def admin_login():
    data = request.get_json() or {}
    hospital_id = data.get('hospital_id')
    password = data.get('password')

    if not hospital_id or not password:
        return jsonify({'message': 'hospital_id and password are required.'}), 400

    hospital = Hospital.find_by_id(hospital_id)
    if not hospital or not Hospital.verify_password(hospital['password_hash'], password):
        return jsonify({'message': 'Invalid Hospital ID or password.'}), 401

    token = generate_token(hospital['id'], 'admin', hospital['name'])
    return jsonify({
        'token': token,
        'role': 'admin',
        'id': hospital['id'],
        'name': hospital['name']
    }), 200

def doctor_register():
    data = request.get_json() or {}
    name = data.get('name')
    specialization = data.get('specialization')
    qualification = data.get('qualification')
    experience = data.get('experience')
    phone = data.get('phone')
    email = data.get('email')
    password = data.get('password')

    if not all([name, specialization, qualification, experience, phone, email, password]):
        return jsonify({'message': 'All fields are required.'}), 400

    if Doctor.find_by_email(email):
        return jsonify({'message': 'A doctor with this email already exists.'}), 400

    try:
        doc_id = Doctor.create(name, specialization, qualification, int(experience), phone, email, password)
        return jsonify({
            'message': 'Doctor registered successfully.',
            'doctor_id': doc_id
        }), 201
    except Exception as e:
        return jsonify({'message': f'Registration failed: {str(e)}'}), 500

def doctor_login():
    data = request.get_json() or {}
    doctor_id = data.get('doctor_id')
    password = data.get('password')

    if not doctor_id or not password:
        return jsonify({'message': 'doctor_id and password are required.'}), 400

    doctor = Doctor.find_by_id(doctor_id)
    if not doctor or not Doctor.verify_password(doctor['password_hash'], password):
        return jsonify({'message': 'Invalid Doctor ID or password.'}), 401

    token = generate_token(doctor['id'], 'doctor', doctor['name'])
    return jsonify({
        'token': token,
        'role': 'doctor',
        'id': doctor['id'],
        'name': doctor['name']
    }), 200

def patient_send_otp():
    data = request.get_json() or {}
    email = data.get('email')

    if not email:
        return jsonify({'message': 'Email address is required.'}), 400

    if Patient.find_by_email(email):
        return jsonify({'message': 'A patient with this email already exists.'}), 400

    otp = generate_otp(email)
    
    # We include the OTP directly in the response so testing is seamless,
    # but also print to console as per real design simulation.
    return jsonify({
        'message': 'Verification code (OTP) sent to email.',
        'otp_simulated': otp  # Simulates sending an email
    }), 200

def patient_register():
    data = request.get_json() or {}
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')
    phone = data.get('phone')
    otp = data.get('otp')

    if not all([name, email, password, phone, otp]):
        return jsonify({'message': 'All fields (name, email, password, phone, otp) are required.'}), 400

    if not verify_otp(email, otp):
        return jsonify({'message': 'Invalid or expired OTP verification code.'}), 400

    if Patient.find_by_email(email):
        return jsonify({'message': 'A patient with this email already exists.'}), 400

    try:
        patient_id = Patient.create(name, email, password, phone)
        return jsonify({
            'message': 'Patient registered and verified successfully.',
            'patient_id': patient_id
        }), 201
    except Exception as e:
        return jsonify({'message': f'Registration failed: {str(e)}'}), 500

def patient_login():
    data = request.get_json() or {}
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'message': 'Email and password are required.'}), 400

    patient = Patient.find_by_email(email)
    if not patient or not Patient.verify_password(patient['password_hash'], password):
        return jsonify({'message': 'Invalid Email or password.'}), 401

    token = generate_token(patient['id'], 'patient', patient['name'])
    return jsonify({
        'token': token,
        'role': 'patient',
        'id': patient['id'],
        'name': patient['name']
    }), 200
