import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:signup/Services/auth_service.dart';
import 'package:signup/loginScreen.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  String? _selectedRole;
  final List<String> roles = ['patient', 'doctor'];
  bool _obscurePassword = true;
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _usernamecontroller = TextEditingController();
  final _emailcontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();
  final _authservice = AuthService();
  bool _isloading = false;

  Future<void> _handlesignup() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate name fields
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your first and last name!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate doctor-specific fields
    if (_selectedRole == 'doctor') {
      if (_specializationController.text.isEmpty || 
          _experienceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all doctor details!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isloading = true;
    });

    try {
      final result = await _authservice.registration(
        email: _emailcontroller.text.trim(),
        password: _passwordcontroller.text,
      );

      if (result == 'Success') {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Create base user data
          final userData = {
            'email': _emailcontroller.text.trim(),
            'username': _usernamecontroller.text.trim(),
            'role': _selectedRole,
            'First name': _firstNameController.text.trim(),
            'Last name': _lastNameController.text.trim(),
          };

          // Add doctor-specific fields if role is doctor
          if (_selectedRole == 'doctor') {
            userData.addAll({
              'specialization': _specializationController.text.trim(),
              'experience': _experienceController.text.trim(),
            });
          }

          // Save user data in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(userData);

          // If role is patient, also create a patient document
          if (_selectedRole == 'patient') {
            await FirebaseFirestore.instance
                .collection('patients')
                .doc(user.uid)
                .set({
                  'First name': _firstNameController.text.trim(),
                  'Last name': _lastNameController.text.trim(),
                  'userId': user.uid,
                  'Age': null,
                  'Gender': null,
                  'Allergies': null,
                  'profileComplete': false,
                });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.lightGreen,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Loginscreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4158D0),
              Color(0xFFC850C0),
              Color(0xFFFFCC70),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Header Section
                  Center(
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          'assets/images/sign-up.svg',
                          height: 150,
                          width: 150,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.25),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join our healthcare community',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Role Dropdown
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedRole,
                            items: roles.map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(
                                role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                              ),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedRole = value),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              hintText: 'Select Role',
                              prefixIcon: Icon(Icons.person_outline, color: Color(0xFF4158D0)),
                            ),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4158D0)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Name Fields
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _firstNameController,
                                hint: 'First Name',
                                icon: Icons.person_outline,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _lastNameController,
                                hint: 'Last Name',
                                icon: Icons.person_outline,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Username and Email Fields
                        _buildTextField(
                          controller: _usernamecontroller,
                          hint: 'Username',
                          icon: Icons.alternate_email,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailcontroller,
                          hint: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        _buildTextField(
                          controller: _passwordcontroller,
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onTogglePassword: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),

                        // Doctor-specific fields
                        if (_selectedRole == 'doctor') ...[
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _specializationController,
                            hint: 'Specialization',
                            icon: Icons.medical_services_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _experienceController,
                            hint: 'Years of Experience',
                            icon: Icons.work_outline,
                            keyboardType: TextInputType.number,
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isloading ? null : _handlesignup,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF4158D0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: _isloading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const Loginscreen()),
                                );
                              },
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: Color(0xFF4158D0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          prefixIcon: Icon(icon, color: const Color(0xFF4158D0)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF4158D0),
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
        ),
      ),
    );
  }
}