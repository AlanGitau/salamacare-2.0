import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signup/core/constants/colors.dart';
import 'package:signup/features/doctor/services/doctor_dashboard_service.dart';
import 'package:signup/features/appointments/services/appointment_service.dart';
import 'package:signup/features/doctor/widgets/patient_medical_quick_view_dialog.dart';
import 'package:signup/features/appointments/screens/AddAppointmentNoteDialog.dart';
import 'package:signup/features/doctor/widgets/doctor_reschedule_appointment_dialog.dart';

class TodayScheduleCard extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const TodayScheduleCard({
    super.key,
    required this.appointments,
    this.isLoading = false,
    this.onRefresh,
  });

  static const Map<String, Color> _statusColors = {
    'scheduled': Color(0xFF90A4AE),
    'confirmed': Color(0xFF42A5F5),
    'checked_in': Color(0xFF66BB6A),
    'in_progress': Color(0xFFFFA726),
    'completed': Color(0xFF78909C),
    'cancelled': Color(0xFFEF5350),
    'no_show': Color(0xFFEF5350),
  };

  static const Map<String, IconData> _statusIcons = {
    'scheduled': Icons.schedule,
    'confirmed': Icons.check_circle_outline,
    'checked_in': Icons.how_to_reg,
    'in_progress': Icons.play_circle_outline,
    'completed': Icons.task_alt,
    'cancelled': Icons.cancel_outlined,
    'no_show': Icons.person_off_outlined,
  };

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.today, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Today's Schedule",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${appointments.length} appts',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (appointments.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              separatorBuilder: (_, __) => Divider(height: 1, indent: 70, color: Colors.grey.shade100),
              itemBuilder: (context, index) => _buildAppointmentItem(context, appointments[index], index),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(BuildContext context, Map<String, dynamic> appointment, int index) {
    final patient = appointment['patients'] as Map<String, dynamic>?;
    final patientName = DoctorDashboardService.getPatientName(patient);
    final appointmentDate = DateTime.parse(appointment['appointment_date'] as String);
    final timeStr = DateFormat('h:mm a').format(appointmentDate);
    final status = appointment['status'] as String? ?? 'scheduled';
    final reason = appointment['reason'] as String? ?? appointment['patient_notes'] as String? ?? '';
    final duration = appointment['duration'] as int? ?? 30;
    final statusColor = _statusColors[status] ?? Colors.grey;
    final statusIcon = _statusIcons[status] ?? Icons.schedule;
    final age = DoctorDashboardService.calculateAge(patient?['date_of_birth'] as String?);

    final now = DateTime.now();
    final isCurrentOrNext = status != 'completed' && status != 'cancelled' && status != 'no_show' &&
        appointmentDate.isBefore(now.add(const Duration(minutes: 30))) &&
        appointmentDate.isAfter(now.subtract(Duration(minutes: duration)));

    return Material(
      color: isCurrentOrNext ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
      child: InkWell(
        onTap: () => _showQuickActions(context, appointment),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              SizedBox(
                width: 58,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isCurrentOrNext ? AppColors.primary : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${duration}m',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              // Timeline indicator
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(color: statusColor.withValues(alpha: 0.3), blurRadius: 4),
                      ],
                    ),
                  ),
                  if (index < appointments.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patientName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 12, color: statusColor),
                              const SizedBox(width: 3),
                              Text(
                                _formatStatus(status),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (age > 0)
                          Text(
                            '$age yrs',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        if (age > 0 && reason.isNotEmpty)
                          Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
                        if (reason.isNotEmpty)
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    if (patient?['allergies'] != null && (patient!['allergies'] as String).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red.shade400),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                'Allergies: ${patient['allergies']}',
                                style: TextStyle(fontSize: 11, color: Colors.red.shade400),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context, Map<String, dynamic> appointment) {
    final patient = appointment['patients'] as Map<String, dynamic>?;
    final patientName = DoctorDashboardService.getPatientName(patient);
    final status = appointment['status'] as String? ?? 'scheduled';
    final appointmentId = appointment['id'] as String;
    final patientId = patient?['id'] as String?;
    final appointmentService = AppointmentService();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(patientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Status: ${_formatStatus(status)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Divider(),
            if (patientId != null)
              _actionTile(
                icon: Icons.medical_information_outlined,
                label: 'View Medical Record',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  PatientMedicalQuickViewDialog.show(
                    context: context,
                    patientId: patientId,
                    patientName: patientName,
                  );
                },
              ),
            if (status == 'scheduled')
              _actionTile(
                icon: Icons.check_circle_outline,
                label: 'Confirm Appointment',
                color: Colors.blue,
                onTap: () async {
                  Navigator.pop(ctx);
                  await appointmentService.updateAppointmentStatus(appointmentId, 'confirmed');
                  onRefresh?.call();
                },
              ),
            if (status == 'scheduled' || status == 'confirmed')
              _actionTile(
                icon: Icons.how_to_reg,
                label: 'Check In Patient',
                color: Colors.green,
                onTap: () async {
                  Navigator.pop(ctx);
                  await appointmentService.updateAppointmentStatus(appointmentId, 'checked_in');
                  onRefresh?.call();
                },
              ),
            if (status == 'checked_in')
              _actionTile(
                icon: Icons.play_circle_outline,
                label: 'Start Consultation',
                color: Colors.orange,
                onTap: () async {
                  Navigator.pop(ctx);
                  await appointmentService.updateAppointmentStatus(appointmentId, 'in_progress');
                  onRefresh?.call();
                },
              ),
            if (status == 'in_progress')
              _actionTile(
                icon: Icons.task_alt,
                label: 'Complete Appointment',
                color: Colors.green.shade700,
                onTap: () async {
                  Navigator.pop(ctx);
                  await appointmentService.updateAppointmentStatus(appointmentId, 'completed');
                  onRefresh?.call();
                },
              ),
            if (status == 'in_progress' || status == 'completed')
              _actionTile(
                icon: Icons.note_add_outlined,
                label: 'Add Clinical Note',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => AddAppointmentNoteDialog(
                      appointmentId: appointmentId,
                      patientName: patientName,
                    ),
                  );
                },
              ),
            if (status != 'completed' && status != 'cancelled' && status != 'no_show')
              _actionTile(
                icon: Icons.schedule_send,
                label: 'Reschedule',
                color: Colors.indigo,
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => DoctorRescheduleAppointmentDialog(
                      appointment: appointment,
                      onRescheduled: () => onRefresh?.call(),
                    ),
                  );
                },
              ),
            if (status != 'completed' && status != 'cancelled' && status != 'no_show')
              _actionTile(
                icon: Icons.person_off_outlined,
                label: 'Mark as No-Show',
                color: Colors.red,
                onTap: () async {
                  Navigator.pop(ctx);
                  await appointmentService.updateAppointmentStatus(appointmentId, 'no_show');
                  onRefresh?.call();
                },
              ),
            if (status != 'completed' && status != 'cancelled' && status != 'no_show')
              _actionTile(
                icon: Icons.cancel_outlined,
                label: 'Cancel Appointment',
                color: Colors.red.shade700,
                onTap: () async {
                  Navigator.pop(ctx);
                  await appointmentService.cancelAppointment(appointmentId, 'Cancelled by doctor');
                  onRefresh?.call();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').split(' ').map((w) =>
        w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  Widget _buildSkeleton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(4, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(width: 50, height: 30, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
              const SizedBox(width: 14),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 14, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(width: 80, height: 10, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No appointments today',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              'Take a well-deserved break!',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
