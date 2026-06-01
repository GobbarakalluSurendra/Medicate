import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../shared/welcome_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _currentIndex = 0;
  final _apiService = ApiService();
  final _authService = AuthService();

  String _patientName = 'Patient';
  String _patientId = '';
  bool _isInitLoading = true;

  // Selected hospital & doctor mapping state
  String? _selectedHospitalId;
  String? _selectedHospitalName;
  List<dynamic> _availableDoctors = [];
  bool _isLoadingDoctors = false;

  // AI Chat states
  final _chatController = TextEditingController();
  final List<Map<String, String>> _aiMessages = [
    {
      'role': 'assistant',
      'text': 'Hello! I am your AI Health Assistant. You can ask me questions about diets, exercise suggestions, or general wellness. Note: I cannot diagnose conditions or write prescriptions.'
    }
  ];
  bool _isAiTyping = false;

  // Reminders Alerts State
  List<Map<String, dynamic>> _followUpAlerts = [];
  bool _isLoadingAlerts = true;

  // Health Tools State
  int _healthToolSubIndex = 0;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  double? _bmiScore;
  String _bmiCategory = "";
  Color _bmiColor = Colors.grey;

  final _dietGoalController = TextEditingController();
  final _dietRestrictionsController = TextEditingController();
  String _dietPlanResult = "";
  bool _isGeneratingDiet = false;

  final _workoutGoalController = TextEditingController();
  final _workoutLevelController = TextEditingController();
  String _workoutPlanResult = "";
  bool _isGeneratingWorkout = false;

  @override
  void initState() {
    super.initState();
    _loadPatientDetails();
    _loadFollowUpAlerts();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _dietGoalController.dispose();
    _dietRestrictionsController.dispose();
    _workoutGoalController.dispose();
    _workoutLevelController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowUpAlerts() async {
    try {
      final prescriptions = await _apiService.patientGetPrescriptions();
      final List<Map<String, dynamic>> alerts = [];
      final now = DateTime.now();
      for (var pr in prescriptions) {
        if (pr['follow_up_date'] != null && pr['follow_up_date'].toString().isNotEmpty) {
          try {
            final followUpDate = DateTime.parse(pr['follow_up_date'].toString());
            // Show alert if follow-up date is today or in the future
            if (followUpDate.isAfter(now.subtract(const Duration(days: 1)))) {
              alerts.add({
                'doctor_name': pr['doctor_name'],
                'doctor_specialization': pr['doctor_specialization'],
                'hospital_name': pr['hospital_name'],
                'follow_up_date': pr['follow_up_date'],
                'diagnosis': pr['diagnosis'],
              });
            }
          } catch (_) {}
        }
      }
      setState(() {
        _followUpAlerts = alerts;
        _isLoadingAlerts = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingAlerts = false;
      });
    }
  }

  Future<void> _loadPatientDetails() async {
    final name = await _authService.getUserName();
    final id = await _authService.getUserId();
    setState(() {
      _patientName = name ?? 'Patient';
      _patientId = id ?? '';
      _isInitLoading = false;
    });
  }

  Future<void> _logout() async {
    await _authService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  // --- WIDGET TAB BUILDERS ---

  // 1. HOSPITAL & BOOKING PORTAL
  Widget _buildBookingPortalTab() {
    if (_selectedHospitalId == null) {
      // List all hospitals
      return FutureBuilder<List<dynamic>>(
        future: _apiService.patientGetHospitals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text("Error fetching hospitals."));
          }
          final list = snapshot.data!;
          if (list.isEmpty) {
            return const Center(child: Text("No hospitals registered yet."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final hosp = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.local_hospital_rounded, color: AppTheme.primaryTeal, size: 36),
                  title: Text(hosp['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(hosp['address']),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryTeal),
                  onTap: () => _selectHospital(hosp['id'], hosp['name']),
                ),
              );
            },
          );
        },
      );
    }

    // List doctors of chosen hospital
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppTheme.primaryTeal.withOpacity(0.08),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.primaryTeal),
                onPressed: () => setState(() => _selectedHospitalId = null),
              ),
              Expanded(
                child: Text(
                  "Doctors at $_selectedHospitalName",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingDoctors
              ? const Center(child: CircularProgressIndicator())
              : _availableDoctors.isEmpty
                  ? const Center(child: Text("No doctors registered at this hospital."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _availableDoctors.length,
                      itemBuilder: (context, index) {
                        final doc = _availableDoctors[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderGrey),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                                radius: 24,
                                child: const Icon(Icons.person, color: AppTheme.primaryTeal),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(doc['specialization'], style: const TextStyle(color: AppTheme.secondaryCyan, fontSize: 13)),
                                    Text("${doc['experience']} Years Experience", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _openBookingSheet(doc['id'], doc['name']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryTeal,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("Book", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        )
      ],
    );
  }

  void _selectHospital(String hospId, String hospName) async {
    setState(() {
      _selectedHospitalId = hospId;
      _selectedHospitalName = hospName;
      _isLoadingDoctors = true;
    });

    try {
      final docs = await _apiService.patientGetHospitalDoctors(hospId);
      setState(() {
        _availableDoctors = docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load doctors list.')),
      );
    } finally {
      setState(() {
        _isLoadingDoctors = false;
      });
    }
  }

  void _openBookingSheet(String doctorId, String doctorName) {
    final symptomsController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<dynamic> doctorSlots = [];
    bool isLoadingSlots = true;
    int? selectedSlotIndex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          if (isLoadingSlots) {
            _apiService.patientGetDoctorSlots(doctorId).then((slots) {
              setSheetState(() {
                doctorSlots = slots;
                isLoadingSlots = false;
              });
            }).catchError((err) {
              setSheetState(() {
                isLoadingSlots = false;
              });
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Book Appointment with $doctorName", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
                    const SizedBox(height: 16),
                    
                    const Text("Select Available Appointment Slot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                    const SizedBox(height: 8),

                    if (isLoadingSlots)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (doctorSlots.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCoral.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.accentCoral.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppTheme.accentCoral),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "This doctor has no available booking slots right now. Please check back later.",
                                style: TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                              ),
                            )
                          ],
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: doctorSlots.length,
                          itemBuilder: (context, index) {
                            final slot = doctorSlots[index];
                            final isSelected = selectedSlotIndex == index;
                            final dateStr = slot['slot_date'];
                            final timeStr = slot['slot_time'];
                            return GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  selectedSlotIndex = index;
                                });
                              },
                              child: Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 12, top: 4, bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryTeal : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryTeal : AppTheme.borderGrey,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: AppTheme.softShadow,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      color: isSelected ? Colors.white : AppTheme.primaryTeal,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeStr.substring(0, 5),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected ? Colors.white70 : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    const Text("Describe Symptoms (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: symptomsController,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: "e.g., Headache for two days, mild cough"),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: selectedSlotIndex == null
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final selectedSlot = doctorSlots[selectedSlotIndex!];

                              final res = await _apiService.patientBookAppointment(
                                doctorId,
                                _selectedHospitalId!,
                                selectedSlot['slot_date'],
                                selectedSlot['slot_time'],
                                symptomsController.text.trim(),
                                slotId: selectedSlot['id'],
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res['message'] ?? 'Appointment booked.')),
                                );
                                Navigator.pop(context);
                                setState(() {
                                  _selectedHospitalId = null;
                                  _currentIndex = 1;
                                });
                                _loadFollowUpAlerts();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Confirm Appointment Booking", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 2. APPOINTMENT BOOKING STATUS
  Widget _buildStatusTab() {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.patientGetAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text("Error fetching records."));
        }
        final list = snapshot.data!;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 48, color: AppTheme.primaryTeal.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text("You have no appointments booked.", style: TextStyle(color: AppTheme.textDark)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final app = list[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderGrey),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("APPT #${app['id']}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryCyan)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: app['status'] == 'completed'
                              ? Colors.green.withOpacity(0.1)
                              : AppTheme.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          app['status'].toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: app['status'] == 'completed' ? Colors.green : AppTheme.primaryTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text("Doctor: ${app['doctor_name']} (${app['doctor_specialization']})", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Location: ${app['hospital_name']}", style: const TextStyle(fontSize: 13)),
                  Text("Address: ${app['hospital_address']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text("Schedule: ${app['appointment_date']} @ ${app['appointment_time']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 3. PRESCRIPTIONS DOWNLOADS
  Widget _buildPrescriptionsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.patientGetPrescriptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text("Error fetching prescriptions."));
        }
        final list = snapshot.data!;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_edu_outlined, size: 48, color: AppTheme.primaryTeal.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text("No medical prescriptions recorded.", style: TextStyle(color: AppTheme.textDark)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final pr = list[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderGrey),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("DIAGNOSIS: ${pr['diagnosis'].toString().toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal)),
                      Text(pr['created_at'].toString().split(' ')[0], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 20),
                  Text("Doctor: ${pr['doctor_name']} (${pr['doctor_specialization']})", style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text("Clinic: ${pr['hospital_name']}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text("Prescribed Treatment:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.secondaryCyan)),
                  Text(pr['medicines'], style: const TextStyle(fontSize: 12, height: 1.4)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _downloadPdf(pr['id']),
                    icon: const Icon(Icons.download, size: 18, color: Colors.white),
                    label: const Text("Download Prescription PDF", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _downloadPdf(int prescId) async {
    try {
      final bytes = await _apiService.downloadPrescriptionPdf(prescId);
      if (bytes != null) {
        // Display positive confirmation
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Download Completed"),
            content: Text(
              "Successfully fetched PDF document bytes from backend ($prescId).\n\n"
              "PDF Size: ${bytes.length} bytes.\n"
              "Document saved locally as Prescription_$prescId.pdf."
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
      } else {
        throw Exception("Failed to retrieve document stream.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate PDF. Make sure ReportLab is installed.')),
      );
    }
  }

  // 4. AI HEALTH ASSISTANT TAB
  Widget _buildAiAssistantTab() {
    return Column(
      children: [
        // AI Advice caution message
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.accentCoral.withOpacity(0.12),
          child: const Row(
            children: [
              Icon(Icons.healing_outlined, color: AppTheme.accentCoral, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "AI Health Assistant provides general guidance only. Consult a doctor for diagnostic advice.",
                  style: TextStyle(fontSize: 11, color: AppTheme.textDark, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _aiMessages.length,
            itemBuilder: (context, index) {
              final msg = _aiMessages[index];
              final isMe = msg['role'] == 'user';
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.primaryTeal : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 16),
                    ),
                    border: isMe ? null : Border.all(color: AppTheme.borderGrey),
                    boxShadow: AppTheme.softShadow,
                  ),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: Text(
                    msg['text']!,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.textDark,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_isAiTyping)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("AI Assistant is writing...", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.borderGrey)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: const InputDecoration(
                    hintText: "Ask about diets, exercises...",
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: AppTheme.primaryTeal),
                onPressed: _sendMessage,
              )
            ],
          ),
        )
      ],
    );
  }

  void _sendMessage() async {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _aiMessages.add({'role': 'user', 'text': query});
      _chatController.clear();
      _isAiTyping = true;
    });

    try {
      final res = await _apiService.chatWithAi(query);
      setState(() {
        _aiMessages.add({
          'role': 'assistant',
          'text': res['reply'] ?? 'Failed to analyze request.'
        });
      });
    } catch (e) {
      setState(() {
        _aiMessages.add({
          'role': 'assistant',
          'text': 'Network error. Make sure server is online.'
        });
      });
    } finally {
      setState(() {
        _isAiTyping = false;
      });
    }
  }

  // 5. PROFILE TAB
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderGrey),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppTheme.primaryTeal, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  _patientName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  "Patient ID: PAT-$_patientId",
                  style: TextStyle(fontSize: 13, color: AppTheme.textDark.withOpacity(0.6), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text("Log Out Session", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCoral,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          )
        ],
      ),
    );
  }

  // --- REMINDER BANNER ---
  Widget _buildReminderBanner() {
    if (_isLoadingAlerts || _followUpAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.2)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm_on_rounded, color: AppTheme.primaryTeal, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Upcoming Follow-up Reminders",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryTeal),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.primaryTeal, size: 18),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _followUpAlerts = [];
                  });
                },
              )
            ],
          ),
          const SizedBox(height: 8),
          ..._followUpAlerts.map((alert) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                "• Recommended follow-up on ${alert['follow_up_date']} with ${alert['doctor_name']} (${alert['doctor_specialization']}) at ${alert['hospital_name']} (Diagnosis: ${alert['diagnosis']}).",
                style: const TextStyle(fontSize: 12, color: AppTheme.textDark, height: 1.3),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- HEALTH TOOLS TAB ---
  Widget _buildHealthToolsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderGrey),
            ),
            child: Row(
              children: [
                _buildSegmentButton(0, "BMI Calculator", Icons.calculate_outlined),
                _buildSegmentButton(1, "Diet Planner", Icons.restaurant_menu_rounded),
                _buildSegmentButton(2, "Workout Planner", Icons.fitness_center_rounded),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSelectedHealthTool(),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton(int index, String label, IconData icon) {
    final isSelected = _healthToolSubIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _healthToolSubIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppTheme.primaryTeal, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedHealthTool() {
    switch (_healthToolSubIndex) {
      case 0:
        return _buildBmiCalculator();
      case 1:
        return _buildDietPlanner();
      case 2:
        return _buildWorkoutPlanner();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBmiCalculator() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Calculate Your Body Mass Index (BMI)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryTeal),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Height (cm)",
              hintText: "e.g., 175",
              prefixIcon: Icon(Icons.height, color: AppTheme.primaryTeal),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Weight (kg)",
              hintText: "e.g., 70",
              prefixIcon: Icon(Icons.monitor_weight_outlined, color: AppTheme.primaryTeal),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _calculateBmi,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Calculate BMI Score", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          if (_bmiScore != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bmiColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _bmiColor.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    "Your BMI Score",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _bmiScore.toString(),
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _bmiColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _bmiCategory.toUpperCase(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _bmiColor, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    _getBmiMessage(_bmiCategory),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textDark, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  void _calculateBmi() {
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    if (height == null || weight == null || height <= 0 || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid positive numbers for height and weight.")),
      );
      return;
    }
    final heightM = height / 100.0;
    final bmi = weight / (heightM * heightM);
    setState(() {
      _bmiScore = double.parse(bmi.toStringAsFixed(2));
      if (_bmiScore! < 18.5) {
        _bmiCategory = "Underweight";
        _bmiColor = Colors.blue;
      } else if (_bmiScore! < 25.0) {
        _bmiCategory = "Normal Weight";
        _bmiColor = Colors.green;
      } else if (_bmiScore! < 30.0) {
        _bmiCategory = "Overweight";
        _bmiColor = Colors.orange;
      } else {
        _bmiCategory = "Obese";
        _bmiColor = Colors.red;
      }
    });
  }

  String _getBmiMessage(String category) {
    switch (category) {
      case "Underweight":
        return "Your BMI is less than 18.5, indicating you are underweight. Consider discussing with your doctor to plan a healthy weight gain strategy.";
      case "Normal Weight":
        return "Fantastic! Your BMI is in the healthy range (18.5 - 24.9). Maintain this with a balanced diet and regular physical activities.";
      case "Overweight":
        return "Your BMI is between 25 and 29.9, placing you in the overweight category. Regular aerobic activities and dietary refinements can assist in reaching the healthy range.";
      case "Obese":
        return "Your BMI is 30 or higher, which falls under obesity. Consult with a qualified healthcare provider for personalized guidance on nutrition and fitness.";
      default:
        return "";
    }
  }

  Widget _buildDietPlanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Gemini AI Diet & Meal Planner",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryTeal),
          ),
          const SizedBox(height: 12),
          const Text(
            "Describe your fitness goals (e.g., weight loss, muscle gain) and list any dietary preferences to let Gemini generate a tailored meal structure.",
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dietGoalController,
            decoration: const InputDecoration(
              labelText: "Fitness/Diet Goal",
              hintText: "e.g., lose 5kg in 2 months, lean bulk",
              prefixIcon: Icon(Icons.flag_outlined, color: AppTheme.primaryTeal),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dietRestrictionsController,
            decoration: const InputDecoration(
              labelText: "Preferences/Restrictions (Optional)",
              hintText: "e.g., vegetarian, vegan, dairy-free, no eggs",
              prefixIcon: Icon(Icons.no_food_outlined, color: AppTheme.primaryTeal),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isGeneratingDiet ? null : () => _generatePlan(true),
            icon: _isGeneratingDiet
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            label: Text(
              _isGeneratingDiet ? "Analyzing Diet Parameters..." : "Generate AI Diet Plan",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_dietPlanResult.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text("Your Custom Diet Plan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryTeal)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: SelectableText(
                _dietPlanResult,
                style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textDark),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildWorkoutPlanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Gemini AI Workout & Routine Planner",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryTeal),
          ),
          const SizedBox(height: 12),
          const Text(
            "Specify your exercise objectives and experience level to generate a weekly split and safety guidance from Gemini.",
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _workoutGoalController,
            decoration: const InputDecoration(
              labelText: "Workout Goal",
              hintText: "e.g., strength training, 5k run prep, home workout",
              prefixIcon: Icon(Icons.track_changes, color: AppTheme.primaryTeal),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _workoutLevelController,
            decoration: const InputDecoration(
              labelText: "Experience/Fitness Level (Optional)",
              hintText: "e.g., beginner, intermediate, advanced",
              prefixIcon: Icon(Icons.show_chart, color: AppTheme.primaryTeal),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isGeneratingWorkout ? null : () => _generatePlan(false),
            icon: _isGeneratingWorkout
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            label: Text(
              _isGeneratingWorkout ? "Structuring Routine..." : "Generate AI Workout Plan",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_workoutPlanResult.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text("Your Custom Workout Routine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryTeal)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: SelectableText(
                _workoutPlanResult,
                style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textDark),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _generatePlan(bool isDiet) async {
    final goal = isDiet ? _dietGoalController.text.trim() : _workoutGoalController.text.trim();
    if (goal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please specify your ${isDiet ? 'dietary' : 'workout'} goal first.")),
      );
      return;
    }

    setState(() {
      if (isDiet) {
        _isGeneratingDiet = true;
        _dietPlanResult = "";
      } else {
        _isGeneratingWorkout = true;
        _workoutPlanResult = "";
      }
    });

    String prompt = "";
    if (isDiet) {
      final restrictions = _dietRestrictionsController.text.trim();
      prompt = "You are a professional clinical dietitian. "
          "Generate a detailed, custom diet, nutrition, and meal plan for a person with the goal: '$goal'. "
          "${restrictions.isNotEmpty ? 'Dietary restrictions/preferences: ' + restrictions : ''}. "
          "Structure the plan with daily meal outlines (breakfast, lunch, dinner, snacks), macro-nutrient guidance (protein, carbs, fats), hydration rules, and a list of foods to prioritize/avoid. Be encouraging, thorough, and present it clearly using bullet points and markdown formatting.";
    } else {
      final experience = _workoutLevelController.text.trim();
      prompt = "You are a professional sports therapist and personal trainer. "
          "Generate a weekly workout routine, exercise plan, and rehabilitation advice for a person with the goal: '$goal'. "
          "${experience.isNotEmpty ? 'Fitness experience level: ' + experience : ''}. "
          "Provide a clear day-by-day split (e.g., Day 1: Upper Body, Day 2: Cardio, etc.), specific exercises with sets/reps/rpe guidelines, warmup/cooldown instructions, and injury prevention safety measures. Present it clearly using bullet points and markdown formatting.";
    }

    try {
      final res = await _apiService.chatWithAi(prompt);
      setState(() {
        if (isDiet) {
          _dietPlanResult = res['reply'] ?? 'Failed to generate diet plan.';
        } else {
          _workoutPlanResult = res['reply'] ?? 'Failed to generate workout routine.';
        }
      });
    } catch (e) {
      setState(() {
        final errorMsg = 'Error communicating with AI assistant. Make sure server is running and GEMINI_API_KEY is configured.';
        if (isDiet) {
          _dietPlanResult = errorMsg;
        } else {
          _workoutPlanResult = errorMsg;
        }
      });
    } finally {
      setState(() {
        if (isDiet) {
          _isGeneratingDiet = false;
        } else {
          _isGeneratingWorkout = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> tabs = [
      _buildBookingPortalTab(),
      _buildStatusTab(),
      _buildPrescriptionsTab(),
      _buildAiAssistantTab(),
      _buildHealthToolsTab(),
      _buildProfileTab(),
    ];

    final List<String> titles = [
      "Select Hospital",
      "Appointment Status",
      "Prescriptions Log",
      "AI Health Assistant",
      "Health & Fitness Tools",
      "Patient Profile",
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          if (_currentIndex != 3 && _currentIndex != 4 && _currentIndex != 5)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {});
                if (_currentIndex == 0) _loadFollowUpAlerts();
              },
            )
        ],
      ),
      body: Column(
        children: [
          _buildReminderBanner(),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: tabs),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index != 0) {
              _selectedHospitalId = null;
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryTeal,
        unselectedItemColor: AppTheme.textDark.withOpacity(0.4),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital_outlined),
            activeIcon: Icon(Icons.local_hospital),
            label: 'Hospitals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            activeIcon: Icon(Icons.medication),
            label: 'Rx',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Tools',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
