import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import 'register_screen.dart';
import '../admin/admin_dashboard.dart';
import '../doctor/doctor_dashboard.dart';
import '../patient/patient_dashboard.dart';

class LoginScreen extends StatefulWidget {
  final String role; // 'admin', 'doctor', or 'patient'
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _authService = AuthService();
  
  final _idOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _idOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _roleTitle {
    if (widget.role == 'admin') return 'Hospital Admin';
    if (widget.role == 'doctor') return 'Practitioner Doctor';
    return 'Patient Portal';
  }

  String get _identifierLabel {
    if (widget.role == 'admin') return 'Hospital ID';
    if (widget.role == 'doctor') return 'Doctor ID';
    return 'Email Address';
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      Map<String, dynamic> result;
      
      if (widget.role == 'admin') {
        result = await _apiService.adminLogin(
          _idOrEmailController.text.trim(),
          _passwordController.text,
        );
      } else if (widget.role == 'doctor') {
        result = await _apiService.doctorLogin(
          _idOrEmailController.text.trim(),
          _passwordController.text,
        );
      } else {
        result = await _apiService.patientLogin(
          _idOrEmailController.text.trim(),
          _passwordController.text,
        );
      }

      if (result.containsKey('token')) {
        // Save auth data
        await _authService.saveSession(
          token: result['token'],
          role: widget.role,
          id: result['id'].toString(),
          name: result['name'] ?? 'User',
        );

        if (!mounted) return;

        // Route to dashboard
        Widget nextDashboard;
        if (widget.role == 'admin') {
          nextDashboard = const AdminDashboard();
        } else if (widget.role == 'doctor') {
          nextDashboard = const DoctorDashboard();
        } else {
          nextDashboard = const PatientDashboard();
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => nextDashboard),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Invalid credentials.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection failed. Please check if backend is running.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login as $_roleTitle'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Text
                Text(
                  "Welcome Back",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Log in using your official credentials to access dashboard",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textDark.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 32),

                // Error Banner
                if (_errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCoral.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentCoral.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Input Field: Hospital ID / Doctor ID / Email
                Text(
                  _identifierLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryTeal),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _idOrEmailController,
                  validator: (value) {
                    if (widget.role == 'patient') {
                      return FormValidators.validateEmail(value);
                    }
                    return FormValidators.validateRequired(value, _identifierLabel);
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      widget.role == 'patient' ? Icons.email_outlined : Icons.badge_outlined,
                      color: AppTheme.primaryTeal.withOpacity(0.7),
                    ),
                    hintText: widget.role == 'patient' ? 'example@mail.com' : 'Enter $_identifierLabel',
                  ),
                ),
                const SizedBox(height: 20),

                // Input Field: Password
                const Text(
                  'Password',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryTeal),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) => FormValidators.validateRequired(value, 'Password'),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outlined, color: AppTheme.primaryTeal.withOpacity(0.7)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    hintText: '••••••••',
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Log In',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 24),

                // Sign Up Redirect
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppTheme.textDark.withOpacity(0.6)),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(role: widget.role),
                          ),
                        );
                      },
                      child: const Text(
                        "Register",
                        style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
