import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Medicalform extends StatefulWidget {
  const Medicalform({super.key});

  @override
  State<Medicalform> createState() => _MedicalformState();
}

class _MedicalformState extends State<Medicalform> {
  final _formkey = GlobalKey<FormState>(); // Key to manage form state
  String bloodtype = '';
  String Allergies = '';
  String medications = '';
  String Contact = '';
  String nextOfKinName = '';
  String NextofKinContact = '';

 void _submitForm() async {
  if (_formkey.currentState!.validate()) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Convert comma-separated strings to arrays
      List<String> allergiesList = Allergies.split(',').map((e) => e.trim()).toList();
      List<String> medicationsList = medications.split(',').map((e) => e.trim()).toList();

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid) // Use the user's UID as the document ID
          .update({
        'Allergies': allergiesList,
        'Medications': medicationsList,
        'Contact': Contact,
        'NextOfKinName': nextOfKinName,
        'NextOfKinContact': NextofKinContact,
        'BloodType': bloodtype,
        'profileComplete': true, // Update patients collection
      });

      // Update users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profileComplete': true, // Update users collection
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Medical data saved!')),
      );

      Navigator.pop(context); // Return to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medical Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Blood Type
                _buildSectionTitle('Blood Type'),
                _buildTextField(
                  label: 'Blood Type',
                  hint: 'e.g., A+',
                  onChanged: (value) => bloodtype = value,
                  validator: (value) => value!.isEmpty ? 'Please enter your blood type' : null,
                ),

                // Allergies
                _buildSectionTitle('Allergies'),
                _buildTextField(
                  label: 'Allergies',
                  hint: 'e.g., Sulphur drugs',
                  onChanged: (value) => Allergies = value,
                  validator: (value) => value!.isEmpty ? 'Please enter your allergies' : null,
                ),

                // Medications
                _buildSectionTitle('Medications'),
                _buildTextField(
                  label: 'Medications',
                  hint: 'e.g., Panadol',
                  onChanged: (value) => medications = value,
                  validator: (value) => value!.isEmpty ? 'Please enter your medications' : null,
                ),

                // Contact Info
                _buildSectionTitle('Contact Information'),
                _buildTextField(
                  label: 'Contact Info',
                  hint: 'e.g., Address or phone number',
                  onChanged: (value) => Contact = value,
                  validator: (value) => value!.isEmpty ? 'Please enter your contact info' : null,
                ),

                // Next of Kin
                _buildSectionTitle('Next of Kin'),
                _buildTextField(
                  label: 'Next of Kin Name',
                  hint: 'e.g., Family member or spouse name',
                  onChanged: (value) => nextOfKinName = value,
                  validator: (value) => value!.isEmpty ? 'Please enter next of kin name' : null,
                ),
                _buildTextField(
                  label: 'Next of Kin Contact',
                  hint: 'e.g., 0713456789',
                  keyboardType: TextInputType.phone,
                  onChanged: (value) => NextofKinContact = value,
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter next of kin contact';
                    String phone = value.trim();
                    RegExp phoneFormat = RegExp(r'^0[0-9]{9}$');
                    if (!phoneFormat.hasMatch(phone)) {
                      return 'Please enter a valid phone number (10 digits, starting with 0)';
                    }
                    return null;
                  },
                ),

                // Submit Button
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Submit', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build section titles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  // Helper method to build text fields
  Widget _buildTextField({
    required String label,
    required String hint,
    required Function(String) onChanged,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
    );
  }
}