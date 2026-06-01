import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../shared/welcome_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _currentIndex = 0;
  final _apiService = ApiService();
  final _authService = AuthService();

  String _doctorName = 'Practitioner';
  String _doctorId = '';
  bool _isInitLoading = true;

  // AI Chat states
  final _chatController = TextEditingController();
  final List<Map<String, String>> _aiMessages = [
    {
      'role': 'assistant',
      'text': 'Hello Doctor! I am your AI Health Assistant. Ask me about fitness plans, dietary suggestions, or general health topics. Please note: I do not replace clinical diagnosis or write direct prescriptions.'
    }
  ];
  bool _isAiTyping = false;

  @override
  void initState() {
    super.initState();
    _loadDoctorDetails();
  }

  Future<void> _loadDoctorDetails() async {
    final name = await _authService.getUserName();
    final id = await _authService.getUserId();
    setState(() {
      _doctorName = name ?? 'Practitioner';
      _doctorId = id ?? '';
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

  // 1. APPOINTMENTS TAB
  Widget _buildAppointmentsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.doctorGetAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text("Error loading appointments."));
        }
        final list = snapshot.data!;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_ind_outlined, size: 48, color: AppTheme.primaryTeal.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text("No appointments assigned.", style: TextStyle(color: AppTheme.textDark)),
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
                      Text(
                        "APPOINTMENT #${app['id']}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.secondaryCyan),
                      ),
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
                      )
                    ],
                  ),
                  const Divider(height: 20),
                  Text("Patient: ${app['patient_name']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Text("Schedule: ${app['appointment_date']} @ ${app['appointment_time']}", style: const TextStyle(fontSize: 13)),
                  if (app['symptoms'] != null) ...[
                    const SizedBox(height: 8),
                    Text("Symptoms: ${app['symptoms']}", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _viewPatientDetails(app['patient_id']),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryTeal),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Patient Info", style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (app['status'] == 'booked')
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showWritePrescriptionSheet(app['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTeal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Prescribe", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _viewPatientDetails(int patientId) async {
    final res = await _apiService.doctorGetPatientDetails(patientId);
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Patient Profile Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person, color: AppTheme.primaryTeal),
              title: const Text("Full Name"),
              subtitle: Text(res['name'] ?? 'N/A'),
            ),
            ListTile(
              leading: const Icon(Icons.email, color: AppTheme.primaryTeal),
              title: const Text("Email Address"),
              subtitle: Text(res['email'] ?? 'N/A'),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: AppTheme.primaryTeal),
              title: const Text("Phone Number"),
              subtitle: Text(res['phone'] ?? 'N/A'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _viewPatientMedicalHistory(patientId, res['name'] ?? 'Patient');
              },
              icon: const Icon(Icons.history_edu, color: Colors.white),
              label: const Text("View Medical History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryCyan,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
              child: const Text("Close", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  void _viewPatientMedicalHistory(int patientId, String patientName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Medical History: $patientName",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _apiService.doctorGetPatientHistory(patientId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return const Center(child: Text("Error fetching medical history records."));
                  }
                  final list = snapshot.data!;
                  if (list.isEmpty) {
                    return const Center(child: Text("No previous prescription records found."));
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final pr = list[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text("Diagnosis: ${pr['diagnosis']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                                Text(pr['created_at'].toString().split(' ')[0], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            const Divider(height: 12),
                            const Text("Medicines:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryTeal)),
                            Text(pr['medicines'], style: const TextStyle(fontSize: 12, height: 1.3)),
                            if (pr['instructions'] != null && pr['instructions'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const Text("Instructions:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryTeal)),
                              Text(pr['instructions'], style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                            ],
                            if (pr['follow_up_date'] != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.event_repeat, size: 14, color: AppTheme.accentCoral),
                                  const SizedBox(width: 4),
                                  Text("Follow-up: ${pr['follow_up_date']}", style: const TextStyle(fontSize: 12, color: AppTheme.accentCoral, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ]
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
              child: const Text("Close", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showWritePrescriptionSheet(int appointmentId) {
    final diagnosisController = TextEditingController();
    final medicinesController = TextEditingController();
    final instructionsController = TextEditingController();
    final followUpController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
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
                const Text("Write Prescription", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
                const SizedBox(height: 16),
                
                const Text("Diagnosis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: diagnosisController,
                  validator: (v) => v == null || v.isEmpty ? 'Diagnosis is required' : null,
                  decoration: const InputDecoration(hintText: "e.g., Acute Pharyngitis, Viral Fever"),
                ),
                const SizedBox(height: 16),

                const Text("Medicines & Dosage List", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: medicinesController,
                  maxLines: 4,
                  validator: (v) => v == null || v.isEmpty ? 'Prescribed medicine is required' : null,
                  decoration: const InputDecoration(
                    hintText: "Enter one medicine per line:\nFormat: Medicine Name - Dosage Info\ne.g., Paracetamol 500mg - 1-0-1 after food",
                  ),
                ),
                const SizedBox(height: 16),

                const Text("Additional Advisory Instructions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: instructionsController,
                  decoration: const InputDecoration(hintText: "e.g., Drink lots of fluids, bed rest for 3 days"),
                ),
                const SizedBox(height: 16),
                const Text("Follow-up Date (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: followUpController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: "Select Follow-up Date",
                    prefixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 180)),
                    );
                    if (picked != null) {
                      setState(() {
                        followUpController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    
                    final res = await _apiService.doctorCreatePrescription(
                      appointmentId,
                      diagnosisController.text.trim(),
                      medicinesController.text.trim(),
                      instructionsController.text.trim(),
                      followUpController.text.isNotEmpty ? followUpController.text : null,
                    );
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res['message'] ?? 'Prescription saved.')),
                      );
                      Navigator.pop(context);
                      setState(() {}); // refresh listings
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Save & Complete Appointment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. PRESCRIPTION HISTORY TAB
  Widget _buildPrescriptionHistoryTab() {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.doctorGetPrescriptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text("Error fetching history."));
        }
        final list = snapshot.data!;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_edu_outlined, size: 48, color: AppTheme.primaryTeal.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text("No historical prescriptions found.", style: TextStyle(color: AppTheme.textDark)),
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
                      Text("PRESCRIPTION #${pr['id']}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryCyan, fontSize: 12)),
                      Text(pr['created_at'].toString().split(' ')[0], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 20),
                  Text("Patient: ${pr['patient_name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text("Diagnosis: ${pr['diagnosis']}", style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  const Text("Medicines:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
                  Text(pr['medicines'], style: const TextStyle(fontSize: 12, height: 1.4)),
                  if (pr['instructions'] != null && pr['instructions'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text("Instructions:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
                    Text(pr['instructions'], style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 3. AI HEALTH ASSISTANT TAB
  Widget _buildAiAssistantTab() {
    return Column(
      children: [
        // Disclaimer warning header
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.accentCoral.withOpacity(0.12),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.accentCoral, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Warning: AI Health Assistant is for guidance only. Verify details before diagnosing.",
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
                    hintText: "Ask about workouts, diets...",
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
          'text': res['reply'] ?? 'Failed to analyze.'
        });
      });
    } catch (e) {
      setState(() {
        _aiMessages.add({
          'role': 'assistant',
          'text': 'Connection failed. Please ensure backend services are active.'
        });
      });
    } finally {
      setState(() {
        _isAiTyping = false;
      });
    }
  }

  // Slots Schedulers states & view builder
  final _slotDateController = TextEditingController();
  final _slotTimeController = TextEditingController();
  bool _isSavingSlot = false;

  Widget _buildAvailabilityTab() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Post Available Time Slot",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryTeal),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _slotDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          hintText: "Date (YYYY-MM-DD)",
                          prefixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setState(() {
                              _slotDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _slotTimeController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          hintText: "Time (HH:MM)",
                          prefixIcon: Icon(Icons.access_time, size: 18),
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (picked != null) {
                            setState(() {
                              _slotTimeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSavingSlot ? null : _addAvailabilitySlot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSavingSlot
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Create Slot", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _apiService.doctorGetSlots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return const Center(child: Text("Error fetching availability slots."));
              }
              final list = snapshot.data!;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 48, color: AppTheme.primaryTeal.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      const Text("No schedule slots created.", style: TextStyle(color: AppTheme.textDark)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final slot = list[index];
                  final isBooked = slot['is_booked'] == 1 || slot['is_booked'] == true;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        isBooked ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isBooked ? Colors.green : AppTheme.secondaryCyan,
                      ),
                      title: Text("${slot['slot_date']} @ ${slot['slot_time']}"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isBooked ? Colors.green.withOpacity(0.1) : AppTheme.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isBooked ? "BOOKED" : "AVAILABLE",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isBooked ? Colors.green : AppTheme.primaryTeal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _addAvailabilitySlot() async {
    final date = _slotDateController.text;
    final time = _slotTimeController.text;
    if (date.isEmpty || time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Date and time must be specified.")));
      return;
    }
    setState(() => _isSavingSlot = true);
    try {
      final res = await _apiService.doctorAddSlot(date, time);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Slot created successfully.')));
        _slotDateController.clear();
        _slotTimeController.clear();
        setState(() {}); // reload future lists
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to publish availability slot.")));
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingSlot = false);
      }
    }
  }

  // 4. PROFILE TAB
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
                  _doctorName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  "Doctor ID: $_doctorId",
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

  @override
  Widget build(BuildContext context) {
    if (_isInitLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> tabs = [
      _buildAppointmentsTab(),
      _buildPrescriptionHistoryTab(),
      _buildAvailabilityTab(),
      _buildAiAssistantTab(),
      _buildProfileTab(),
    ];

    final List<String> titles = [
      "Assigned Bookings",
      "Prescription History",
      "Manage Available Slots",
      "AI Health Assistant",
      "Doctor Profile",
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          if (_currentIndex == 0 || _currentIndex == 1 || _currentIndex == 2)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            )
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryTeal,
        unselectedItemColor: AppTheme.textDark.withOpacity(0.4),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Appts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Prescriptions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm_add_outlined),
            activeIcon: Icon(Icons.alarm_add),
            label: 'Slots',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'AI Guide',
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
