import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signup/core/constants/colors.dart';
import 'package:signup/features/doctor/services/doctor_dashboard_service.dart';

class NextAppointmentBanner extends StatelessWidget {
  final Map<String, dynamic>? appointment;
  final VoidCallback? onViewRecord;
  final VoidCallback? onStartAppointment;
  final bool isLoading;

  const NextAppointmentBanner({
    super.key,
    this.appointment,
    this.onViewRecord,
    this.onStartAppointment,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();
    if (appointment == null) return _buildEmptyState();

    final patient = appointment!['patients'] as Map<String, dynamic>?;
    final patientName = DoctorDashboardService.getPatientName(patient);
    final appointmentDate = DateTime.parse(appointment!['appointment_date'] as String);
    final timeStr = DateFormat('h:mm a').format(appointmentDate);
    final reason = appointment!['reason'] as String? ?? appointment!['patient_notes'] as String? ?? 'General Consultation';
    final duration = appointment!['duration'] as int? ?? 30;
    final status = appointment!['status'] as String? ?? 'scheduled';

    final now = DateTime.now();
    final difference = appointmentDate.difference(now);
    final minutesUntil = difference.inMinutes;

    // Urgency colors
    Color urgencyColor;
    String countdownText;
    if (minutesUntil < 0) {
      urgencyColor = Colors.red.shade400;
      countdownText = 'Overdue by ${-minutesUntil} min';
    } else if (minutesUntil <= 15) {
      urgencyColor = Colors.red.shade400;
      countdownText = 'In $minutesUntil min';
    } else if (minutesUntil <= 30) {
      urgencyColor = Colors.amber.shade600;
      countdownText = 'In $minutesUntil min';
    } else if (minutesUntil <= 60) {
      urgencyColor = Colors.green.shade500;
      countdownText = 'In $minutesUntil min';
    } else if (difference.inHours < 24) {
      urgencyColor = AppColors.primary;
      final hours = difference.inHours;
      final mins = minutesUntil % 60;
      countdownText = mins > 0 ? 'In ${hours}h ${mins}m' : 'In ${hours}h';
    } else {
      urgencyColor = AppColors.primary;
      countdownText = 'In ${difference.inDays} days';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [urgencyColor, urgencyColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: urgencyColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'NEXT PATIENT',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    countdownText,
                    style: TextStyle(
                      color: urgencyColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  child: Text(
                    patientName.isNotEmpty ? patientName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '$timeStr  •  $duration min',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                          if (patient?['date_of_birth'] != null) ...[
                            Text(
                              '  •  ${DoctorDashboardService.calculateAge(patient!['date_of_birth'] as String?)} yrs',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.note_alt_outlined, color: Colors.white.withValues(alpha: 0.9), size: 14),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      reason,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewRecord,
                    icon: const Icon(Icons.medical_information_outlined, size: 16),
                    label: const Text('View Record'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (status == 'checked_in' || status == 'confirmed' || status == 'scheduled')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onStartAppointment,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(status == 'checked_in' ? 'Start' : 'Check In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: urgencyColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.quaternary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.quaternary),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available, size: 40, color: AppColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            'No upcoming appointments',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enjoy your free time!',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
