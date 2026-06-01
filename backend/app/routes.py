from flask import Blueprint
from app.utils.auth_middleware import token_required
from app import controllers

api_bp = Blueprint('api', __name__)

# ==========================================
# AUTHENTICATION & REGISTRATION ENDPOINTS
# ==========================================
api_bp.route('/admin/register', methods=['POST'])(controllers.admin_register)
api_bp.route('/admin/login', methods=['POST'])(controllers.admin_login)
api_bp.route('/doctor/register', methods=['POST'])(controllers.doctor_register)
api_bp.route('/doctor/login', methods=['POST'])(controllers.doctor_login)
api_bp.route('/patient/otp/send', methods=['POST'])(controllers.patient_send_otp)
api_bp.route('/patient/register', methods=['POST'])(controllers.patient_register)
api_bp.route('/patient/login', methods=['POST'])(controllers.patient_login)


# ==========================================
# ADMIN DASHBOARD ENDPOINTS
# ==========================================
@api_bp.route('/admin/doctor/add', methods=['POST'])
@token_required(allowed_roles=['admin'])
def route_admin_add_doctor(current_user):
    return controllers.admin_add_doctor(current_user)

@api_bp.route('/admin/doctors', methods=['GET'])
@token_required(allowed_roles=['admin'])
def route_admin_view_doctors(current_user):
    return controllers.admin_view_doctors(current_user)

@api_bp.route('/admin/patients', methods=['GET'])
@token_required(allowed_roles=['admin'])
def route_admin_view_patients(current_user):
    return controllers.admin_view_patients(current_user)

@api_bp.route('/admin/appointments', methods=['GET'])
@token_required(allowed_roles=['admin'])
def route_admin_view_appointments(current_user):
    return controllers.admin_view_appointments(current_user)


# ==========================================
# DOCTOR DASHBOARD ENDPOINTS
# ==========================================
@api_bp.route('/doctor/appointments', methods=['GET'])
@token_required(allowed_roles=['doctor'])
def route_doctor_view_appointments(current_user):
    return controllers.doctor_view_appointments(current_user)

@api_bp.route('/doctor/patient/<int:patient_id>', methods=['GET'])
@token_required(allowed_roles=['doctor'])
def route_doctor_view_patient_details(current_user, patient_id):
    return controllers.doctor_view_patient_details(current_user, patient_id)

@api_bp.route('/doctor/patient/<int:patient_id>/history', methods=['GET'])
@token_required(allowed_roles=['doctor'])
def route_doctor_view_patient_history(current_user, patient_id):
    return controllers.doctor_view_patient_history(current_user, patient_id)

@api_bp.route('/doctor/prescription/create', methods=['POST'])
@token_required(allowed_roles=['doctor'])
def route_doctor_create_prescription(current_user):
    return controllers.doctor_create_prescription(current_user)

@api_bp.route('/doctor/prescriptions', methods=['GET'])
@token_required(allowed_roles=['doctor'])
def route_doctor_view_prescription_history(current_user):
    return controllers.doctor_view_prescription_history(current_user)

@api_bp.route('/doctor/slots', methods=['POST'])
@token_required(allowed_roles=['doctor'])
def route_doctor_add_slot(current_user):
    return controllers.doctor_add_slot(current_user)

@api_bp.route('/doctor/slots', methods=['GET'])
@token_required(allowed_roles=['doctor'])
def route_doctor_get_own_slots(current_user):
    return controllers.doctor_get_own_slots(current_user)


# ==========================================
# PATIENT DASHBOARD ENDPOINTS
# ==========================================
@api_bp.route('/patient/hospitals', methods=['GET'])
@token_required(allowed_roles=['patient'])
def route_patient_view_hospitals(current_user):
    return controllers.patient_view_hospitals(current_user)

@api_bp.route('/patient/hospital/<string:hosp_id>/doctors', methods=['GET'])
@token_required(allowed_roles=['patient'])
def route_patient_view_hospital_doctors(current_user, hosp_id):
    return controllers.patient_view_hospital_doctors(current_user, hosp_id)

@api_bp.route('/patient/doctor/<string:doctor_id>/slots', methods=['GET'])
@token_required(allowed_roles=['patient'])
def route_patient_get_doctor_slots(current_user, doctor_id):
    return controllers.patient_get_doctor_slots(current_user, doctor_id)

@api_bp.route('/patient/appointment/book', methods=['POST'])
@token_required(allowed_roles=['patient'])
def route_patient_book_appointment(current_user):
    return controllers.patient_book_appointment(current_user)

@api_bp.route('/patient/appointments', methods=['GET'])
@token_required(allowed_roles=['patient'])
def route_patient_view_appointments(current_user):
    return controllers.patient_view_appointments(current_user)

@api_bp.route('/patient/prescriptions', methods=['GET'])
@token_required(allowed_roles=['patient'])
def route_patient_view_prescription_history(current_user):
    return controllers.patient_view_prescription_history(current_user)


# ==========================================
# SHARED SECURE ENDPOINTS
# ==========================================
@api_bp.route('/patient/prescription/<int:presc_id>/pdf', methods=['GET'])
@token_required(allowed_roles=['patient', 'doctor'])
def route_download_prescription_pdf(current_user, presc_id):
    return controllers.download_prescription_pdf(current_user, presc_id)

@api_bp.route('/ai/chat', methods=['POST'])
@token_required(allowed_roles=['patient', 'doctor'])
def route_chat_assistant(current_user):
    return controllers.chat_assistant(current_user)
