import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarView extends StatefulWidget {
  final String doctorId;
  const CalendarView({super.key, required this.doctorId});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late Map<DateTime, List<Map<String, dynamic>>> _appointments;
  bool _isLoading = true;
  String? _errorMessage;

  // Constants to improve code readability and maintenance
  static const int _appointmentQueryLimit = 100;
  static const double _listSpacing = 16.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _focusedDay;
    _appointments = {};
    _loadAppointments();
  }

  // Extract Firestore query to its own method
  Stream<QuerySnapshot> _getAppointmentsStream() {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: widget.doctorId)
        .orderBy('appointmentDate')
        .orderBy('appointmentTime')
        .limit(_appointmentQueryLimit)
        .snapshots();
  }

  // Separate method to handle appointment loading
  void _loadAppointments() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getAppointmentsStream(),
      builder: (context, snapshot) {
        // Handle error state
        if (snapshot.hasError) {
          _errorMessage = 'Error loading appointments: ${snapshot.error}';
          return _buildErrorState();
        }

        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
          return _buildLoadingState();
        }

        // Process appointments data when available
        if (snapshot.hasData) {
          try {
            _processAppointments(snapshot.data!.docs);
            _isLoading = false;
          } catch (e) {
            _errorMessage = 'Error processing appointments: $e';
            return _buildErrorState();
          }
          return _buildCalendarContent();
        }

        // Fallback - show empty calendar
        return _buildCalendarContent();
      },
    );
  }

  // Extract UI components to separate methods
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          SelectableText(
            _errorMessage ?? 'An unknown error occurred',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAppointments,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading appointments...'),
        ],
      ),
    );
  }

  // FIX: Wrap with a Scaffold to provide proper scrolling context 
  Widget _buildCalendarContent() {
    return Scaffold(
      // Using body as a SingleChildScrollView to ensure everything scrolls properly
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCalendar(),
            const SizedBox(height: _listSpacing),
            _buildAppointmentListSection(),
          ],
        ),
      ),
    );
  }

  void _processAppointments(List<QueryDocumentSnapshot> docs) {
    try {
      _appointments.clear();
      
      for (var doc in docs) {
        if (doc.data() is! Map<String, dynamic>) {
          continue;
        }
        
        final data = doc.data() as Map<String, dynamic>;
        
        final timestamp = data['appointmentDate'];
        if (timestamp is! Timestamp) {
          continue;
        }
        
        final date = timestamp.toDate();
        final dateKey = DateTime(date.year, date.month, date.day);

        _appointments[dateKey] ??= [];
        
        final timeString = data['appointmentTime'] as String? ?? '00:00';
        
        _appointments[dateKey]!.add({
          'id': doc.id,
          'time': _formatTime(timeString),
          'status': data['status'] as String? ?? 'Scheduled',
          'dateTime': dateKey.add(_parseTime(timeString)),
          'patientId': data['userId'] as String? ?? '',
          'patientName': data['patientName'] as String? ?? 'Unknown Patient',
        });
      }
    } catch (e) {
      throw Exception('Failed to process appointments: $e');
    }
  }

  Duration _parseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length < 2) return Duration.zero;
      
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return Duration(hours: hour, minutes: minute);
    } catch (e) {
      return Duration.zero;
    }
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length < 2) return time;
      
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: (day) {
        final normalizedDay = DateTime(day.year, day.month, day.day);
        return _appointments[normalizedDay] ?? [];
      },
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.amber,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
    );
  }

  // FIX: Modified to avoid layout constraints issues
  Widget _buildAppointmentListSection() {
    if (_selectedDay == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Select a day to view appointments')),
      );
    }

    final normalizedDay = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final appointments = _appointments[normalizedDay] ?? [];

    if (appointments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No appointments on ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Sort appointments by time
    appointments.sort((a, b) => (a['dateTime'] as DateTime).compareTo(b['dateTime'] as DateTime));

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text(
              'Appointments on ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          // FIX: Use ListView.builder directly without nested Column/ListView
          ListView.builder(
            // FIX: These two properties are crucial to fix the overflow
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return _buildAppointmentCard(appointment);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      elevation: 2.0,
      child: ListTile(
        leading: Icon(
          _getStatusIcon(appointment['status']),
          color: _getStatusColor(appointment['status']),
          size: 28,
        ),
        title: Text(
          'Appointment at ${appointment['time']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${appointment['status']}'),
            Text('Patient: ${appointment['patientName'] ?? 'Unknown'}'),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.info, color: Colors.blue),
          onPressed: () => _showAppointmentDetails(
            appointment['id'],
            appointment['patientId'],
          ),
          tooltip: 'View details',
        ),
        onTap: () => _showAppointmentDetails(
          appointment['id'],
          appointment['patientId'],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'rescheduled':
        return Icons.update;
      default:
        return Icons.event;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  Future<void> _showAppointmentDetails(String appointmentId, String patientId) async {
    if (appointmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot load details: Invalid appointment ID')),
      );
      return;
    }
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading appointment details...'),
            ],
          ),
        ),
      );
      
      // Fetch appointment details
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .get();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Handle document not found
      if (!appointmentDoc.exists || appointmentDoc.data() == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment details not found')),
        );
        return;
      }
      
      // Show appointment details dialog
      final data = appointmentDoc.data()!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Appointment Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Date', _formatDate(data['appointmentDate'])),
                _buildDetailRow('Time', _formatTime(data['appointmentTime'] ?? '00:00')),
                _buildDetailRow('Status', data['status'] ?? 'Unknown'),
                _buildDetailRow('Patient ID', patientId),
                // Add more details as needed
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (patientId.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Implement navigation to patient profile
                  // Navigator.push(...);
                },
                child: const Text('View Patient'),
              ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appointment details: $e')),
      );
    }
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('MMM dd, yyyy').format(date);
    }
    return 'Unknown';
  }
}