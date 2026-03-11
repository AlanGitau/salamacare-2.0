import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:signup/DoctorDashboard.dart';
import 'package:signup/Homepage.dart';
import 'package:signup/MedicalForm.dart';
import 'package:signup/Services/auth_service.dart';
import 'package:signup/signup.dart';

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

 Future<void> _handleLogin() async {
  setState(() => _isLoading = true);
  try {
    final result = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (result == 'Success') {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get user role and profileComplete from users collection
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userRole = userDoc['role'];
        final profileComplete = userDoc['profileComplete'] ?? false; // Default to false if missing

        if (userRole == 'doctor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Doctordashboard()),
          );
        } else {
          if (profileComplete) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Homepage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Medicalform()),
            );
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ?? 'Authentication failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:  const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4158D0),
              Color(0xFFC850C0),
              Color(0xFFFFCC70),
            ],
            //colors: [Colors.blue.shade700, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/images/authenticaton.svg', height: 150,),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    
                    ),
                  
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            //Email textfield
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email),
                                labelText: 'Email',
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                            ),


                            const SizedBox(height: 25),

                            //password textfield
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                labelText: 'Password',
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                            ),
                            const SizedBox(height: 15),

                            
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
                              ),
                            ),

                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Forgot Password?', style: TextStyle(color: Colors.blueAccent)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(color: Colors.white)),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Signup()),
                        ),
                        child: const Text('Sign Up', style: TextStyle(color: Colors.yellowAccent)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
