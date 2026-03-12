import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signup/core/constants/colors.dart';
import 'package:signup/features/doctor/services/doctor_dashboard_service.dart';
import 'package:signup/features/appointments/services/appointment_service.dart';
import 'package:signup/features/doctor/widgets/patient_medical_quick_view_dialog.dart';

class PatientQueueCard extends StatelessWidget {
  final List<Map<String, dynamic>> checkedInPatients;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const PatientQueueCard({
    super.key,
    required this.checkedInPatients,
    this.isLoading = false,
    this.onRefresh,
  });

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
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.people_alt_outlined, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Patient Queue',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                if (checkedInPatients.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${checkedInPatients.length} waiting',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (checkedInPatients.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: checkedInPatients.length,
              separatorBuilder: (_, __) => Divider(height: 1, indent: 70, color: Colors.grey.shade100),
              itemBuilder: (context, index) => _buildQueueItem(context, checkedInPatients[index], index),
            ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(BuildContext context, Map<String, dynamic> appointment, int position) {
    final patient = appointment['patients'] as Map<String, dynamic>?;
    final patientName = DoctorDashboardService.getPatientName(patient);
    final patientId = patient?['id'] as String?;
    final appointmentId = appointment['id'] as String;
    final checkedInAt = appointment['checked_in_at'] as String?;
    final appointmentTime = DateTime.parse(appointment['appointment_date'] as String);
    final timeStr = DateFormat('h:mm a').format(appointmentTime);

    // Calculate wait time
    String waitTimeStr = '';
    bool isLongWait = false;
    if (checkedInAt != null) {
      final checkInTime = DateTime.parse(checkedInAt);
      final waitMinutes = DateTime.now().difference(checkInTime).inMinutes;
      if (waitMinutes < 60) {
        waitTimeStr = '${waitMinutes}m wait';
      } else {
        waitTimeStr = '${waitMinutes ~/ 60}h ${waitMinutes % 60}m wait';
      }
      isLongWait = waitMinutes > 30;
    }

    return Material(
      color: isLongWait ? Colors.red.withValues(alpha: 0.03) : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Position badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${position + 1}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Patient avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.quaternary,
              child: Text(
                patientName.isNotEmpty ? patientName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Patient info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (waitTimeStr.isNotEmpty) ...[
                        Text('  •  ', style: TextStyle(color: Colors.grey.shade400)),
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: isLongWait ? Colors.red.shade400 : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          waitTimeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: isLongWait ? Colors.red.shade400 : Colors.grey.shade500,
                            fontWeight: isLongWait ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            IconButton(
              icon: const Icon(Icons.medical_information_outlined, size: 20),
              color: AppColors.primary,
              tooltip: 'View Record',
              onPressed: () {
                if (patientId != null) {
                  PatientMedicalQuickViewDialog.show(
                    context: context,
                    patientId: patientId,
                    patientName: patientName,
                  );
                }
              },
            ),
            const SizedBox(width: 4),
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: () async {
                  final service = AppointmentService();
                  await service.updateAppointmentStatus(appointmentId, 'in_progress');
                  onRefresh?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Start', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
                const SizedBox(width: 12),
                Container(width: 100, height: 16, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.chair_outlined, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'No patients waiting',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
