import unittest
from unittest.mock import patch, MagicMock
import json
import datetime
from app import create_app
from app.utils.auth_middleware import generate_token

class TelemedicineApiTestCase(unittest.TestCase):
    def setUp(self):
        """Sets up test environment before each test case."""
        # Patch the database init so boot does not fail on missing MySQL server
        with patch('app.models.database.init_db') as mock_init:
            self.app = create_app()
            self.client = self.app.test_client()
            self.app_context = self.app.app_context()
            self.app_context.push()

    def tearDown(self):
        """Cleans up environment after test cases."""
        self.app_context.pop()

    # ==========================================
    # 1. AUTHENTICATION & ENROLLMENTS TESTS
    # ==========================================
    @patch('app.models.hospital.Hospital.create')
    @patch('app.models.hospital.Hospital.find_by_email')
    def test_admin_register_success(self, mock_find_email, mock_create):
        mock_find_email.return_value = None
        mock_create.return_value = 'HOSP001' # Sequential ID format matching spec
        
        payload = {
            'name': 'City General Hospital',
            'address': '123 Health Ave, NY',
            'email': 'admin@citygeneral.com',
            'password': 'AdminSecurePassword123'
        }
        
        response = self.client.post('/api/admin/register', 
                                    data=json.dumps(payload),
                                    content_type='application/json')
        
        self.assertEqual(response.status_code, 201)
        data = json.loads(response.data)
        self.assertEqual(data['hospital_id'], 'HOSP001')
        self.assertIn('registered successfully', data['message'])

    @patch('app.models.hospital.Hospital.find_by_id')
    @patch('app.models.hospital.Hospital.verify_password')
    def test_admin_login_success(self, mock_verify, mock_find_id):
        mock_find_id.return_value = {
            'id': 'HOSP001',
            'name': 'City General Hospital',
            'password_hash': 'somehashvalue'
        }
        mock_verify.return_value = True
        
        payload = {
            'hospital_id': 'HOSP001',
            'password': 'AdminSecurePassword123'
        }
        
        response = self.client.post('/api/admin/login',
                                    data=json.dumps(payload),
                                    content_type='application/json')
                                    
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertIn('token', data)
        self.assertEqual(data['role'], 'admin')

    @patch('app.models.doctor.Doctor.create')
    @patch('app.models.doctor.Doctor.find_by_email')
    def test_doctor_register_success(self, mock_find_email, mock_create):
        mock_find_email.return_value = None
        mock_create.return_value = 'DOC001' # Sequential ID format matching spec
        
        payload = {
            'name': 'Dr. Sarah Connor',
            'specialization': 'Cardiology',
            'qualification': 'MD, FACC', # Added qualification field
            'experience': 12,
            'phone': '+15550192',
            'email': 'sarah@citygeneral.com',
            'password': 'DoctorSecretPassword123'
        }
        
        response = self.client.post('/api/doctor/register',
                                    data=json.dumps(payload),
                                    content_type='application/json')
                                    
        self.assertEqual(response.status_code, 201)
        data = json.loads(response.data)
        self.assertEqual(data['doctor_id'], 'DOC001')

    @patch('app.controllers.auth_controller.generate_otp')
    @patch('app.models.patient.Patient.find_by_email')
    def test_patient_otp_generation(self, mock_find_email, mock_gen_otp):
        mock_find_email.return_value = None
        mock_gen_otp.return_value = '112233'
        
        payload = {'email': 'john.doe@gmail.com'}
        response = self.client.post('/api/patient/otp/send',
                                    data=json.dumps(payload),
                                    content_type='application/json')
                                    
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['otp_simulated'], '112233')

    # ==========================================
    # 2. DOCTOR AVAILABILITY SLOTS TESTS
    # ==========================================
    @patch('app.models.doctor.Doctor.add_availability_slot')
    def test_doctor_add_slot(self, mock_add_slot):
        mock_add_slot.return_value = True
        token = generate_token('DOC001', 'doctor', 'Dr. Sarah Connor')
        headers = {'Authorization': f'Bearer {token}'}
        
        payload = {
            'date': '2026-06-15',
            'time': '10:30:00'
        }
        
        response = self.client.post('/api/doctor/slots',
                                    headers=headers,
                                    data=json.dumps(payload),
                                    content_type='application/json')
                                    
        self.assertEqual(response.status_code, 201)
        data = json.loads(response.data)
        self.assertIn('added successfully', data['message'])

    @patch('app.models.doctor.Doctor.get_available_slots')
    def test_patient_get_doctor_slots(self, mock_get_slots):
        mock_get_slots.return_value = [
            {'id': 1, 'slot_date': '2026-06-15', 'slot_time': '10:30:00', 'is_booked': False}
        ]
        token = generate_token(42, 'patient', 'John Doe')
        headers = {'Authorization': f'Bearer {token}'}
        
        response = self.client.get('/api/patient/doctor/DOC001/slots', headers=headers)
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]['slot_time'], '10:30:00')

    # ==========================================
    # 3. MEDICAL HISTORY TRACKING TESTS
    # ==========================================
    @patch('app.models.prescription.Prescription.get_by_patient')
    def test_doctor_view_patient_history(self, mock_get_presc):
        mock_get_presc.return_value = [
            {
                'id': 501,
                'diagnosis': 'Seasonal Allergies',
                'medicines': 'Cetirizine 10mg',
                'created_at': '2026-06-01 10:00:00',
                'doctor_name': 'Dr. Sarah Connor',
                'hospital_name': 'City General Hospital'
            }
        ]
        token = generate_token('DOC001', 'doctor', 'Dr. Sarah Connor')
        headers = {'Authorization': f'Bearer {token}'}
        
        response = self.client.get('/api/doctor/patient/42/history', headers=headers)
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]['diagnosis'], 'Seasonal Allergies')

    # ==========================================
    # 4. BOOKING & PRESCRIPTION TESTS
    # ==========================================
    @patch('app.models.appointment.Appointment.create')
    def test_patient_book_appointment(self, mock_create):
        mock_create.return_value = 101
        
        token = generate_token(42, 'patient', 'John Doe')
        headers = {'Authorization': f'Bearer {token}'}
        payload = {
            'doctor_id': 'DOC001',
            'hospital_id': 'HOSP001',
            'date': '2026-06-15',
            'time': '10:30:00',
            'symptoms': 'Mild fatigue and sore throat',
            'slot_id': 1
        }
        
        response = self.client.post('/api/patient/appointment/book',
                                    headers=headers,
                                    data=json.dumps(payload),
                                    content_type='application/json')
                                    
        self.assertEqual(response.status_code, 201)
        data = json.loads(response.data)
        self.assertEqual(data['appointment_id'], 101)

    @patch('app.models.appointment.Appointment.find_by_id')
    @patch('app.models.prescription.Prescription.create')
    @patch('app.models.appointment.Appointment.update_status')
    def test_doctor_create_prescription(self, mock_update, mock_presc_create, mock_find_app):
        mock_find_app.return_value = {
            'id': 101,
            'patient_id': 42,
            'doctor_id': 'DOC001'
        }
        mock_presc_create.return_value = 501
        mock_update.return_value = 1
        
        token = generate_token('DOC001', 'doctor', 'Dr. Sarah Connor')
        headers = {'Authorization': f'Bearer {token}'}
        payload = {
            'appointment_id': 101,
            'diagnosis': 'Seasonal Allergies',
            'medicines': 'Cetirizine 10mg: Once daily before sleep',
            'instructions': 'Avoid allergens',
            'follow_up_date': '2026-06-30' # Added follow-up parameter
        }
        
        response = self.client.post('/api/doctor/prescription/create',
                                    headers=headers,
                                    data=json.dumps(payload),
                                    content_type='application/json')
                                    
        self.assertEqual(response.status_code, 201)
        data = json.loads(response.data)
        self.assertIn('Prescription saved', data['message'])

if __name__ == '__main__':
    unittest.main()
