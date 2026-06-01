import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'utils/theme.dart';
import 'views/shared/welcome_screen.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/doctor/doctor_dashboard.dart';
import 'views/patient/patient_dashboard.dart';

void main() async {
  // Ensure Flutter engine services are active before running async logic
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = AuthService();
  final loggedIn = await authService.isLoggedIn();
  final role = await authService.getUserRole();
  
  runApp(MyApp(isLoggedIn: loggedIn, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? role;

  const MyApp({super.key, required this.isLoggedIn, this.role});

  @override
  Widget build(BuildContext context) {
    // Session redirection rules
    Widget homeWidget = const WelcomeScreen();
    if (isLoggedIn && role != null) {
      if (role == 'admin') {
        homeWidget = const AdminDashboard();
      } else if (role == 'doctor') {
        homeWidget = const DoctorDashboard();
      } else if (role == 'patient') {
        homeWidget = const PatientDashboard();
      }
    }

    return MaterialApp(
      title: 'Aegis Health Telemedicine',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: homeWidget,
    );
  }
}
