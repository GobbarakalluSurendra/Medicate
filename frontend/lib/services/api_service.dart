import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  // Helper method for headers
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': '69420', // Bypass ngrok warning page
    };
    if (requireAuth) {
      final token = await _authService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // Generic POST request helper
  Future<http.Response> _post(String endpoint, Map<String, dynamic> body, {bool requireAuth = true}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);
    return await http.post(uri, headers: headers, body: jsonEncode(body));
  }

  // Generic GET request helper
  Future<http.Response> _get(String endpoint, {bool requireAuth = true}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);
    return await http.get(uri, headers: headers);
  }

  // ==========================================
  // AUTH API CALLS
  // ==========================================
  Future<Map<String, dynamic>> adminRegister(String name, String address, String email, String password) async {
    final response = await _post('/admin/register', {
      'name': name,
      'address': address,
      'email': email,
      'password': password,
    }, requireAuth: false);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> adminLogin(String hospitalId, String password) async {
    final response = await _post('/admin/login', {
      'hospital_id': hospitalId,
      'password': password,
    }, requireAuth: false);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> doctorRegister(String name, String specialization, String qualification, String experience, String phone, String email, String password) async {
    final response = await _post('/doctor/register', {
      'name': name,
      'specialization': specialization,
      'qualification': qualification,
      'experience': experience,
      'phone': phone,
      'email': email,
      'password': password,
    }, requireAuth: false);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> doctorLogin(String doctorId, String password) async {
    final response = await _post('/doctor/login', {
      'doctor_id': doctorId,
      'password': password,
    }, requireAuth: false);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> patientSendOtp(String email) async {
    final response = await _post('/patient/otp/send', {
      'email': email,
    }, requireAuth: false);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> patientRegister(String name, String email, String password, String phone, String otp) async {
    final response = await _post('/patient/register', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'otp': otp,
    }, requireAuth: false);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> patientLogin(String email, String password) async {
    final response = await _post('/patient/login', {
      'email': email,
      'password': password,
    }, requireAuth: false);
    return jsonDecode(response.body);
  }

  // ==========================================
  // ADMIN DASHBOARD API CALLS
  // ==========================================
  Future<Map<String, dynamic>> adminAddDoctor(String doctorId) async {
    final response = await _post('/admin/doctor/add', {
      'doctor_id': doctorId,
    });
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> adminGetDoctors() async {
    final response = await _get('/admin/doctors');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load doctors: ${response.body}');
  }

  Future<List<dynamic>> adminGetPatients() async {
    final response = await _get('/admin/patients');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load patients: ${response.body}');
  }

  Future<List<dynamic>> adminGetAppointments() async {
    final response = await _get('/admin/appointments');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load appointments: ${response.body}');
  }

  // ==========================================
  // DOCTOR DASHBOARD API CALLS
  // ==========================================
  Future<List<dynamic>> doctorGetAppointments() async {
    final response = await _get('/doctor/appointments');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load appointments: ${response.body}');
  }

  Future<Map<String, dynamic>> doctorGetPatientDetails(int patientId) async {
    final response = await _get('/doctor/patient/$patientId');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> doctorCreatePrescription(int appointmentId, String diagnosis, String medicines, String instructions, [String? followUpDate]) async {
    final response = await _post('/doctor/prescription/create', {
      'appointment_id': appointmentId,
      'diagnosis': diagnosis,
      'medicines': medicines,
      'instructions': instructions,
      if (followUpDate != null) 'follow_up_date': followUpDate,
    });
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> doctorGetPrescriptions() async {
    final response = await _get('/doctor/prescriptions');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load prescription history: ${response.body}');
  }

  Future<Map<String, dynamic>> doctorAddSlot(String date, String time) async {
    final response = await _post('/doctor/slots', {
      'date': date,
      'time': time,
    });
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> doctorGetSlots() async {
    final response = await _get('/doctor/slots');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load slots: ${response.body}');
  }

  Future<List<dynamic>> doctorGetPatientHistory(int patientId) async {
    final response = await _get('/doctor/patient/$patientId/history');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load patient history: ${response.body}');
  }

  // ==========================================
  // PATIENT DASHBOARD API CALLS
  // ==========================================
  Future<List<dynamic>> patientGetHospitals() async {
    final response = await _get('/patient/hospitals');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load hospitals: ${response.body}');
  }

  Future<List<dynamic>> patientGetHospitalDoctors(String hospId) async {
    final response = await _get('/patient/hospital/$hospId/doctors');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load doctors: ${response.body}');
  }

  Future<List<dynamic>> patientGetDoctorSlots(String doctorId) async {
    final response = await _get('/patient/doctor/$doctorId/slots');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load availability slots: ${response.body}');
  }

  Future<Map<String, dynamic>> patientBookAppointment(String doctorId, String hospitalId, String date, String time, String symptoms, {int? slotId}) async {
    final response = await _post('/patient/appointment/book', {
      'doctor_id': doctorId,
      'hospital_id': hospitalId,
      'date': date,
      'time': time,
      'symptoms': symptoms,
      if (slotId != null) 'slot_id': slotId,
    });
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> patientGetAppointments() async {
    final response = await _get('/patient/appointments');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load appointments: ${response.body}');
  }

  Future<List<dynamic>> patientGetPrescriptions() async {
    final response = await _get('/patient/prescriptions');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load prescriptions: ${response.body}');
  }

  // Binary stream helper for ReportLab PDFs
  Future<List<int>?> downloadPrescriptionPdf(int prescId) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/patient/prescription/$prescId/pdf');
    final token = await _authService.getToken();
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': '69420',
      },
    );
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    return null;
  }

  // ==========================================
  // AI ASSISTANT API CALLS
  // ==========================================
  Future<Map<String, dynamic>> chatWithAi(String message) async {
    final response = await _post('/ai/chat', {
      'message': message,
    });
    return jsonDecode(response.body);
  }
}
