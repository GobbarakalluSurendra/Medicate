import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../shared/welcome_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  final _apiService = ApiService();
  final _authService = AuthService();
  
  String _hospitalName = 'Hospital Admin';
  String _hospitalId = '';
  bool _isInitLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHospitalDetails();
  }

  Future<void> _loadHospitalDetails() async {
    final name = await _authService.getUserName();
    final id = await _authService.getUserId();
    setState(() {
      _hospitalName = name ?? 'Hospital Admin';
      _hospitalId = id ?? '';
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

  // --- WIDGETS FOR TABS ---

  // 1. APPOINTMENTS TAB
  Widget _buildAppointmentsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.adminGetAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text("Error fetching appointments."));
        }
        final list = snapshot.data!;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 48, color: AppTheme.primaryTeal.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text("No appointments scheduled yet.", style: TextStyle(color: AppTheme.textDark)),
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
                        "Appt ID: #${app['id']}",
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
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18, color: AppTheme.primaryTeal),
                      const SizedBox(width: 8),
                      Text("Patient: ${app['patient_name']}", style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.medical_services_outlined, size: 18, color: AppTheme.primaryTeal),
                      const SizedBox(width: 8),
                      Text("Doctor: ${app['doctor_name']} (${app['doctor_specialization']})", style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined, size: 18, color: AppTheme.primaryTeal),
                      const SizedBox(width: 8),
                      Text("Schedule: ${app['appointment_date']} @ ${app['appointment_time']}", style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  if (app['symptoms'] != null && app['symptoms'].toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.lightBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Symptoms: ${app['symptoms']}",
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    )
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 2. DOCTORS TAB
  Widget _buildDoctorsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.adminGetDoctors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text("Error fetching doctors list."));
        }
        final list = snapshot.data!;
        return Column(
          children: [
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_information_outlined, size: 48, color: AppTheme.primaryTeal.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          const Text("No doctors added to this hospital yet.", style: TextStyle(color: AppTheme.textDark)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final doc = list[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                              child: const Icon(Icons.person_rounded, color: AppTheme.primaryTeal),
                            ),
                            title: Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${doc['specialization']} • ${doc['experience']} Years Exp\nPhone: ${doc['phone']}"),
                            trailing: Text("ID: ${doc['id']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _showAddDoctorDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Add Doctor to Hospital", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Add doctor dialog trigger
  void _showAddDoctorDialog() {
    final docIdController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Doctor by ID"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter the unique registration ID of the doctor (e.g. DOC-XXXXXX):", style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: docIdController,
              decoration: const InputDecoration(
                hintText: "DOC-919283",
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = docIdController.text.trim();
              if (id.isEmpty) return;
              
              final res = await _apiService.adminAddDoctor(id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Action completed.')),
                );
                Navigator.pop(context);
                setState(() {}); // Reload tab
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
            child: const Text("Associate", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // 3. PATIENTS TAB
  Widget _buildPatientsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.adminGetPatients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text("Error fetching patients list."));
        }
        final list = snapshot.data!;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: AppTheme.primaryTeal.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text("No patients records in this hospital yet.", style: TextStyle(color: AppTheme.textDark)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final pat = list[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.secondaryCyan.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppTheme.secondaryCyan),
                ),
                title: Text(pat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Email: ${pat['email']}\nPhone: ${pat['phone']}"),
                trailing: Text("ID: PAT-${pat['id']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
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
                  child: const Icon(Icons.local_hospital, color: AppTheme.primaryTeal, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  _hospitalName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  "Hospital ID: $_hospitalId",
                  style: TextStyle(fontSize: 13, color: AppTheme.textDark.withOpacity(0.6), fontWeight: FontWeight.w600),
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
      _buildDoctorsTab(),
      _buildPatientsTab(),
      _buildProfileTab(),
    ];

    final List<String> titles = [
      "Hospital Bookings",
      "Doctors Directory",
      "Registered Patients",
      "Admin Profile",
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          if (_currentIndex != 3)
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
            icon: Icon(Icons.book_online_outlined),
            activeIcon: Icon(Icons.book_online),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Doctors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_outlined),
            activeIcon: Icon(Icons.admin_panel_settings),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
