import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:signup/loginScreen.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'calendar_view.dart';

class Doctordashboard extends StatefulWidget {
  const Doctordashboard({super.key});

  @override
  State<Doctordashboard> createState() => _DoctordashboardState();
}

class _DoctordashboardState extends State<Doctordashboard> {
  String? get _currentDoctorId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Builder(
          builder: (context) {
            return IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: const Icon(Icons.menu, color: Colors.black),
            );
          }
        ),
        title: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'search',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              )
            ),
            const SizedBox(width: 15),
            ElevatedButton(
              onPressed: (){}, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 2,
              ),
              child: const Text('New appointment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500))
            ),
            const SizedBox(width: 15),
            const CircleAvatar(
              backgroundImage: AssetImage('assets/images/boy.png'),
              radius: 20,
            ),
          ],
        ),
      ),
      drawer: Drawer(
        elevation: 15,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          )
        ),
        backgroundColor: Colors.grey.shade50,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:[Colors.blue.shade700,Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end:Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/images/Salamacare logo.png', width: 50, height: 50),
                  const SizedBox(width: 10),
                  const Text('Salama care',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              )
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.blue.shade600),
              title: Text('Appointments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              onTap: (){},
              horizontalTitleGap: 16,
              tileColor: Colors.transparent,
              splashColor: Colors.blue.withOpacity(0.1),
              hoverColor: Colors.blue.withOpacity(0.05),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.people, color: Colors.blue.shade600),
              title: Text('patients',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              onTap: (){},
              horizontalTitleGap: 16,
              tileColor: Colors.transparent,
              splashColor: Colors.blue.withOpacity(0.1),
              hoverColor: Colors.blue.withOpacity(0.05),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.blue.shade600),
              title: Text('settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              onTap: (){},
              horizontalTitleGap: 16,
              tileColor: Colors.transparent,
              splashColor: Colors.blue.withOpacity(0.1),
              hoverColor: Colors.blue.withOpacity(0.05),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade300, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Log out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pushReplacement(context, 
                  MaterialPageRoute(builder: (context)=> const Loginscreen()),
                );
              },
              horizontalTitleGap: 16,
              tileColor: Colors.transparent,
              splashColor: Colors.red.withOpacity(0.1),
              hoverColor: Colors.red.withOpacity(0.05),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return _buildWideLayout();
            } else {
              return _buildNarrowLayout();
            }
          },
        ),
      ),
    );
  }

 // First, update your _buildWideLayout() method to place the calendar next to the appointment tables
Widget _buildWideLayout() {
  return Column(
    children: [
      // Stats Cards at top (full width)
      Column(
        children: [
          const Text('Today\'s appointments',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Row(
            children: [
              const statcard(
                title: 'Upcoming appointments', 
                color: Colors.amber, 
                count: '10', 
                icon: Icons.upcoming),
              const statcard(
                title: 'Completed Appointments', 
                color: Colors.green, 
                count: '5', 
                icon: Icons.check_circle),
              statcard(
                title:'missed Apointments', 
                color: Colors.orange.shade200, 
                count: '2', 
                icon: Icons.hourglass_empty),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      // Calendar and Appointments side by side (in the main content area)
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar View on the left
            Expanded(
              flex: 2,
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.only(right: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CalendarView(doctorId: _currentDoctorId ?? ''),
                ),
              ),
            ),
            
            // Appointments Table on the right
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Appointment details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextButton(
                        onPressed: (){}, 
                        child: const Text('view all')),
                    ],
                  ),
                  const Expanded(child: AppointmentTables()),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// Also fix the narrow layout to maintain consistency
Widget _buildNarrowLayout() {
  return Column(
    children: [
      // Stats Cards
      Column(
        children: [
          const Text('Today\'s appointments',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Row(
            children: [
              const statcard(
                title: 'Upcoming appointments', 
                color: Colors.amber, 
                count: '10', 
                icon: Icons.upcoming),
              const statcard(
                title: 'Completed Appointments', 
                color: Colors.green, 
                count: '5', 
                icon: Icons.check_circle),
              statcard(
                title:'missed Apointments', 
                color: Colors.orange.shade200, 
                count: '2', 
                icon: Icons.hourglass_empty),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      // Calendar View (in narrow layout, it's stacked vertically)
      Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            height: 400,
            child: CalendarView(doctorId: _currentDoctorId ?? ''),
          ),
        ),
      ),
      const SizedBox(height: 16),
      
      // Appointments Table
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Appointment details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: (){}, 
                  child: const Text('view all')),
              ],
            ),
            const Expanded(child: AppointmentTables()),
          ],
        ),
      ),
    ],
  );
}
}

// ... [Rest of your existing code for statcard, AppointmentTables, and PatientProfileScreen classes]

class statcard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final IconData icon;

  const statcard({
    super.key,
    required this.title,
    required this.color,
    required this.count,
    required this.icon,});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),//Adds spacing between cards
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: color, //passed the color object stored in the statcard widget
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //card icon
            Icon(
              icon,
              size: 32,
              color: Colors.black54,
              ),
            const SizedBox(height: 15,),
//Card Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: Colors.black87
                ),
            ),
            const SizedBox(height: 4,),
//count 
            Text(
              count,
              style: const TextStyle(fontSize: 28, 
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              ),
            ),
          ],

        ),
      ),
    );
  }
}

// AppointmentTables class (merged and updated)
class AppointmentTables extends StatelessWidget {
  const AppointmentTables({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentDoctorId = FirebaseAuth.instance.currentUser?.uid;

    if (currentDoctorId == null) {
      return const Center(child: Text('No user logged in'));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black12,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: currentDoctorId)
            .orderBy('appointmentDate', descending: true)
            .orderBy('appointmentTime', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Error in StreamBuilder: ${snapshot.error}');
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data?.docs ?? [];

          if (appointments.isEmpty) {
            return const Center(child: Text('No appointments found'));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                columns: const [
                  DataColumn(label: Text('Patient Name')),
                  DataColumn(label: Text('Appointment Date')),
                  DataColumn(label: Text('Appointment Time')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: appointments.map((doc) {
                  Map<String, dynamic> data;
                  try {
                    data = doc.data() as Map<String, dynamic>;
                  } catch (e) {
                    print('Error parsing document data: $e');
                    return const DataRow(cells: [
                      DataCell(Text('Error')),
                      DataCell(Text('Error')),
                      DataCell(Text('Error')),
                      DataCell(Text('Error')),
                      DataCell(Text('Error')),
                    ]);
                  }

                  return DataRow(cells: [
                    DataCell(
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientProfileScreen(
                                patientId: data['userId'],
                              ),
                            ),
                          );
                        },
                        child: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('patients')
                              .doc(data['userId'])
                              .get(),
                          builder: (context, patientSnapshot) {
                            if (patientSnapshot.hasError) {
                              print('Error fetching patient: ${patientSnapshot.error}');
                              return const Text('Error loading patient');
                            }
                            
                            if (patientSnapshot.hasData) {
                              try {
                                final patientData = patientSnapshot.data?.data() as Map<String, dynamic>;
                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Text(
                                    '${patientData['First name']} ${patientData['Last name']}',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                print('Error parsing patient data: $e');
                                return const Text('Error parsing patient data');
                              }
                            }
                            return const Text('Loading...');
                          },
                        ),
                      ),
                    ),
                    DataCell(Text(_formatFullDate(data['appointmentDate'] as Timestamp))),
                    DataCell(Text(_formatTime(data['appointmentTime']))),
                    DataCell(Text(data['status'] ?? 'Scheduled')),
                    DataCell(Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _rescheduleAppointment(doc.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Reschedule', style: TextStyle(fontSize: 12,color:Colors.white )),
                        ),
                        const SizedBox(width: 5),
                        ElevatedButton(
                          onPressed: () => _cancelAppointment(doc.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatFullDate(Timestamp timestamp) {
    try {
      final date = timestamp.toDate();
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      print('Error formatting date: $e');
      return 'Invalid date';
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return 'N/A';
    
    try {
      final timeFormat = DateFormat('HH:mm');
      final dateTime = timeFormat.parse(timeString);
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      print('Error formatting time: $e');
      return timeString;
    }
  }

  Future<void> _rescheduleAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'status': 'Rescheduled',
          });
    } catch (e) {
      print('Error rescheduling appointment: $e');
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': 'Cancelled'});
    } catch (e) {
      print('Error cancelling appointment: $e');
    }
  }
}
               
              
              
// patient_profile_screen.dart

class PatientProfileScreen extends StatelessWidget {
  final String patientId;

  const PatientProfileScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patient Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading Patient Data...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Patient not found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final patientData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Personal Information'),
                _buildInfoRow(Icons.person, 'Name',
                    '${patientData['First name']} ${patientData['Last name']}'),
                _buildInfoRow(Icons.phone, 'Contact', patientData['Contact'] ?? 'N/A'),
                _buildInfoRow(Icons.bloodtype, 'Blood Type', patientData['BloodType'] ?? 'N/A'),
                _buildInfoRow(Icons.cake, 'Age', patientData['Age']?.toString() ?? 'N/A'),
                _buildInfoRow(Icons.transgender, 'Gender', patientData['Gender'] ?? 'N/A'),

                const SizedBox(height: 24),
                _buildSectionHeader('Medical Information'),
                _buildListInfo('Allergies', patientData['Allergies']),
                _buildListInfo('Medications', patientData['Medications']),

                const SizedBox(height: 24),
                _buildSectionHeader('Emergency Contact'),
                _buildInfoRow(Icons.emergency, 'Name', patientData['NextOfKinName'] ?? 'N/A'),
                _buildInfoRow(Icons.phone, 'Contact', patientData['NextOfKinContact'] ?? 'N/A'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(
          thickness: 1,
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.blueAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'N/A',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListInfo(String title, List<dynamic>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => Chip(
            label: Text(
              item.toString(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blueAccent,
              ),
            ),
            backgroundColor: Colors.blue[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          )).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
