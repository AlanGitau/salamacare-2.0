import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({super.key});

  @override
  _BookAppointmentPageState createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  String? selectedDoctor;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  List<Map<String, dynamic>> doctors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      setState(() {
        doctors = querySnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['username'],
                })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching doctors: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4158D0).withOpacity(0.8),
              const Color(0xFFC850C0).withOpacity(0.8),
              const Color(0xFFFFCC70).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                expandedHeight: 200,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Book Appointment',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF4158D0).withOpacity(0.3),
                          const Color(0xFFC850C0).withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Select Your Doctor', Icons.person_outline),
                        const SizedBox(height: 16),
                        if (isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selectedDoctor,
                              items: doctors.map((doctor) {
                                return DropdownMenuItem<String>(
                                  value: doctor['id'],
                                  child: Text(doctor['name']),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedDoctor = value;
                                });
                              },
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                fillColor: Colors.transparent,
                                filled: true,
                              ),
                            ),
                          ),

                        const SizedBox(height: 32),
                        _buildSectionTitle('Choose Date', Icons.calendar_today_outlined),
                        const SizedBox(height: 16),
                        _buildSelectionCard(
                          onTap: () async {
                            DateTime? date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF4158D0),
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          title: selectedDate == null
                              ? "Select Date"
                              : "${selectedDate!.toLocal()}".split(' ')[0],
                          icon: Icons.calendar_today_outlined,
                        ),

                        const SizedBox(height: 32),
                        _buildSectionTitle('Choose Time', Icons.access_time_outlined),
                        const SizedBox(height: 16),
                        _buildSelectionCard(
                          onTap: () async {
                            TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF4158D0),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              setState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          title: selectedTime == null
                              ? "Select Time"
                              : selectedTime!.format(context),
                          icon: Icons.access_time_outlined,
                        ),

                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (selectedDoctor != null &&
                                  selectedDate != null &&
                                  selectedTime != null) {
                                try {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    await FirebaseFirestore.instance
                                        .collection('appointments')
                                        .add({
                                      'userId': user.uid,
                                      'doctorId': selectedDoctor,
                                      'appointmentDate': selectedDate,
                                      'appointmentTime':
                                          '${selectedTime!.hour}:${selectedTime!.minute}',
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Appointment booked successfully"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error booking appointment: $e")),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please fill all fields")),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4158D0),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              "Confirm Appointment",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF4158D0),
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4158D0),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required VoidCallback onTap,
    required String title,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF4158D0)),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 16,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF4158D0),
        ),
      ),
    );
  }
}