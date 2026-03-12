import 'package:flutter/material.dart';
import 'package:signup/core/constants/colors.dart';
import 'package:signup/features/doctor/screens/DoctorAppointmentsScreen.dart';
import 'package:signup/features/doctor/screens/AvailabilityManagementScreen.dart';
import 'package:signup/features/doctor/screens/BlockedTimeSlotsScreen.dart';
import 'package:signup/features/doctor/screens/DoctorProfileForm.dart';
import 'package:signup/features/doctor/services/doctor_service.dart';

class QuickActionsBar extends StatelessWidget {
  final String doctorId;
  final bool isAcceptingPatients;
  final VoidCallback? onToggleAccepting;
  final VoidCallback? onRefresh;

  const QuickActionsBar({
    super.key,
    required this.doctorId,
    required this.isAcceptingPatients,
    this.onToggleAccepting,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionChip(
            context: context,
            icon: isAcceptingPatients ? Icons.toggle_on : Icons.toggle_off,
            label: isAcceptingPatients ? 'Accepting' : 'Not Accepting',
            color: isAcceptingPatients ? Colors.green : Colors.grey,
            filled: true,
            onTap: () => _toggleAccepting(context),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            context: context,
            icon: Icons.list_alt,
            label: 'All Appointments',
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoctorAppointmentsScreen()),
            ),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            context: context,
            icon: Icons.schedule,
            label: 'Availability',
            color: AppColors.secondary,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AvailabilityManagementScreen()),
              );
              onRefresh?.call();
            },
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            context: context,
            icon: Icons.block,
            label: 'Block Time',
            color: Colors.orange,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlockedTimeSlotsScreen()),
              );
              onRefresh?.call();
            },
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            context: context,
            icon: Icons.person_outline,
            label: 'Edit Profile',
            color: AppColors.accent,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorProfileForm()),
              );
              onRefresh?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return Material(
      color: filled ? color.withValues(alpha: 0.15) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filled ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleAccepting(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAcceptingPatients ? 'Stop Accepting Patients?' : 'Start Accepting Patients?'),
        content: Text(
          isAcceptingPatients
              ? 'New patients will not be able to book appointments with you.'
              : 'Patients will be able to book appointments with you again.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final service = DoctorService();
      await service.updateDoctorProfile(
        isAcceptingPatients: !isAcceptingPatients,
      );
      onToggleAccepting?.call();
    }
  }
}
