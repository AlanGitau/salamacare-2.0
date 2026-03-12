import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:signup/core/constants/colors.dart';
import 'package:signup/features/appointments/services/appointment_service.dart';
import 'package:signup/features/doctor/services/doctor_service.dart';

/// Dialog for doctors to reschedule patient appointments
class DoctorRescheduleAppointmentDialog extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onRescheduled;

  const DoctorRescheduleAppointmentDialog({
    super.key,
    required this.appointment,
    required this.onRescheduled,
  });

  @override
  State<DoctorRescheduleAppointmentDialog> createState() =>
      _DoctorRescheduleAppointmentDialogState();
}

class _DoctorRescheduleAppointmentDialogState
    extends State<DoctorRescheduleAppointmentDialog> {
  final AppointmentService _appointmentService = AppointmentService();
  final DoctorService _doctorService = DoctorService();
  final TextEditingController _reasonController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedTime;
  List<DateTime> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isRescheduling = false;

  @override
  void initState() {
    super.initState();
    // Set initial selected date to tomorrow
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _loadAvailableSlots();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTime = null;
    });

    try {
      final doctorId = widget.appointment['doctor_id'] as String;

      final slots = await _doctorService.getAvailableTimeSlots(
        doctorId,
        _selectedDate,
      );

      if (mounted) {
        setState(() {
          _availableSlots = slots;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading time slots: $e')),
        );
      }
    }
  }

  Future<void> _rescheduleAppointment() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    // Require reason for doctor-initiated reschedules
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for rescheduling'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isRescheduling = true;
    });

    try {
      final result = await _appointmentService.rescheduleAppointment(
        appointmentId: widget.appointment['id'] as String,
        newAppointmentDate: _selectedTime!,
        duration: widget.appointment['duration'] as int,
        rescheduleReason: _reasonController.text.trim(),
        rescheduledBy: 'doctor', // Important: mark as doctor-initiated
      );

      if (mounted) {
        setState(() {
          _isRescheduling = false;
        });

        if (result['success'] == true) {
          Navigator.of(context).pop();
          widget.onRescheduled();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Appointment rescheduled successfully! Patient has been notified.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  result['message'] ?? 'Failed to reschedule appointment'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRescheduling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDate =
        DateTime.parse(widget.appointment['appointment_date'] as String);
    final patientName =
        '${widget.appointment['patients']['first_name']} ${widget.appointment['patients']['last_name']}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_month,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reschedule Appointment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        'Patient: $patientName',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Current appointment info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Appointment',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy • h:mm a')
                              .format(currentDate),
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notice about patient notification
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.mail_outline, color: Colors.amber[900], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Patient will be notified via in-app notification and email',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Calendar
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select New Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 90)),
                      focusedDay: _selectedDate,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDate, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        if (selectedDay.isAfter(
                            DateTime.now().subtract(const Duration(days: 1)))) {
                          setState(() {
                            _selectedDate = selectedDay;
                          });
                          _loadAvailableSlots();
                        }
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.tertiary.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Available time slots
                    const Text(
                      'Select New Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isLoadingSlots
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _availableSlots.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No available slots for this date',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableSlots.map((slot) {
                                  final isSelected = _selectedTime != null &&
                                      _selectedTime!.isAtSameMomentAs(slot);
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedTime = slot;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? AppColors.primaryGradient
                                            : null,
                                        color:
                                            isSelected ? null : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        DateFormat('h:mm a').format(slot),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                    const SizedBox(height: 24),

                    // Reason (required for doctor)
                    const Text(
                      'Reason for Rescheduling *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'e.g., Emergency surgery, Schedule conflict, etc.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This reason will be shared with the patient',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isRescheduling ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isRescheduling || _selectedTime == null
                        ? null
                        : _rescheduleAppointment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                    child: _isRescheduling
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Reschedule & Notify Patient'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
