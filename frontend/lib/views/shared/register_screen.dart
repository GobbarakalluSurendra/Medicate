import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  final String role; // 'admin', 'doctor', or 'patient'
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Common fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Admin fields
  final _addressController = TextEditingController();

  // Doctor fields
  final _specializationController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();

  // Patient OTP fields
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  String _simulatedOtp = '';
  String _errorMessage = '';
  String _successId = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _specializationController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _roleTitle {
    if (widget.role == 'admin') return 'Hospital';
    if (widget.role == 'doctor') return 'Doctor';
    return 'Patient';
  }

  Future<void> _sendOtp() async {
    if (FormValidators.validateEmail(_emailController.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email to receive verification code.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final res = await _apiService.patientSendOtp(_emailController.text.trim());
      if (res.containsKey('otp_simulated')) {
        setState(() {
          _otpSent = true;
          _simulatedOtp = res['otp_simulated'];
        });
        
        // Show simulated OTP in dialog for testing efficiency
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("OTP Simulation"),
            content: Text("Simulated verification code sent to client console:\n\nVerification Code: $_simulatedOtp"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to send OTP.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to backend server.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.role == 'patient' && !_otpSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please request and verify OTP first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successId = '';
    });

    try {
      Map<String, dynamic> res;

      if (widget.role == 'admin') {
        res = await _apiService.adminRegister(
          _nameController.text.trim(),
          _addressController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else if (widget.role == 'doctor') {
        res = await _apiService.doctorRegister(
          _nameController.text.trim(),
          _specializationController.text.trim(),
          _qualificationController.text.trim(),
          _experienceController.text.trim(),
          _phoneController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        res = await _apiService.patientRegister(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          _phoneController.text.trim(),
          _otpController.text.trim(),
        );
      }

      if (res.containsKey('hospital_id')) {
        setState(() {
          _successId = res['hospital_id'];
        });
      } else if (res.containsKey('doctor_id')) {
        setState(() {
          _successId = res['doctor_id'];
        });
      } else if (res.containsKey('message') && widget.role == 'patient') {
        // Patients do not have auto-generated ID, they login by email
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Registration failed.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Check your server connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register as $_roleTitle'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_successId.isEmpty) ...[
                  Text(
                    "Create Account",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
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

                  // Common Input Field: Name
                  const Text('Full Name / Hospital Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryTeal)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    validator: (value) => FormValidators.validateRequired(value, 'Name'),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryTeal),
                      hintText: 'Enter name',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Common Input Field: Email
                  const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryTeal)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    validator: (value) => FormValidators.validateEmail(value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryTeal),
                      hintText: 'email@example.com',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Admin Input Field: Address
                  if (widget.role == 'admin') ...[
                    const Text('Hospital Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryTeal)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _addressController,
                      validator: (value) => FormValidators.validateRequired(value, 'Hospital Address'),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primaryTeal),
                        hintText: '123 Medical St, Area',
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Doctor Input Fields: Specialization & Experience
                  if (widget.role == 'doctor') ...[
                    const Text('Specialization', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryTeal)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _specializationController,
                      validator: (value) => FormValidators.validateRequired(value, 'Specialization'),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.psychology_outlined, color: AppTheme.primaryTeal),
                        hintText: 'e.g. Cardiology, Pediatrics',
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Qualification', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryTeal)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _qualificationController,
                      validator: (value) => FormValidators.validateRequired(value, 'Qualification'),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.school_outlined, color: AppTheme.primaryTeal),
                        hintText: 'e.g. MBBS, MD, FACC',
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    const Text('Experience (Years)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryTeal)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      validator: (value) => FormValidators.validateRequired(value, 'Experience'),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.timelapse_outlined, color: AppTheme.primaryTeal),
                        hintText: 'e.g. 5',
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Doctor / Patient Input Field: Phone
                  if (widget.role != 'admin') ...[
                    const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryTeal)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) => FormValidators.validatePhone(value),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryTeal),
                        hintText: '+123456789',
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Patient Input Field: OTP Verification Row
                  if (widget.role == 'patient') ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Verification Code (OTP)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryTeal)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.lock_clock_outlined, color: AppTheme.primaryTeal),
                                  hintText: 'Enter 6-digit OTP',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 56, // Match height of decoration
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTeal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Get OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Common Input Field: Password
                  const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryTeal)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    validator: (value) => FormValidators.validateRequired(value, 'Password'),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryTeal),
                      hintText: '••••••••',
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Register Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
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
                            'Register Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ] else ...[
                  // Success Registration Container showing generated ID
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.borderGrey),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppTheme.secondaryCyan, size: 72),
                        const SizedBox(height: 20),
                        const Text(
                          "Registration Completed!",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Write down your auto-generated login ID:",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textDark.withOpacity(0.6), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderGrey),
                          ),
                          child: Text(
                            _successId,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          ),
                          child: const Text('Back to Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
