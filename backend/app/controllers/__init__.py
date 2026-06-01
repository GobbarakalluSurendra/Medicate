from app.controllers.auth_controller import (
    admin_register, admin_login,
    doctor_register, doctor_login,
    patient_send_otp, patient_register, patient_login
)
from app.controllers.doctor_controller import (
    admin_add_doctor, admin_view_doctors, admin_view_patients,
    doctor_add_slot, doctor_get_own_slots
)
from app.controllers.appointment_controller import (
    patient_view_hospitals, patient_view_hospital_doctors,
    patient_book_appointment, patient_view_appointments,
    doctor_view_appointments, doctor_view_patient_details,
    admin_view_appointments, patient_get_doctor_slots,
    doctor_view_patient_history
)
from app.controllers.prescription_controller import (
    doctor_create_prescription, doctor_view_prescription_history,
    patient_view_prescription_history, download_prescription_pdf
)
from app.controllers.ai_controller import chat_assistant
