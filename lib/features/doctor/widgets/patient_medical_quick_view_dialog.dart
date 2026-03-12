import 'package:flutter/material.dart';
import 'package:signup/features/doctor/widgets/patient_medical_quick_view.dart';

/// Dialog wrapper for Patient Medical Quick View
///
/// Provides a full-screen dialog to display comprehensive patient medical records
class PatientMedicalQuickViewDialog {
  /// Show full patient medical records in a dialog
  static Future<void> show({
    required BuildContext context,
    required String patientId,
    required String patientName,
  }) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Patient Medical Records',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          patientName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
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
              const Divider(),
              const SizedBox(height: 8),

              // Content
              Expanded(
                child: PatientMedicalQuickView(
                  patientId: patientId,
                  showFullDetails: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show patient summary in a bottom sheet (quick view without full details)
  static Future<void> showSummary({
    required BuildContext context,
    required String patientId,
    required String patientName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        patientName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      show(
                        context: context,
                        patientId: patientId,
                        patientName: patientName,
                      );
                    },
                    icon: const Icon(Icons.open_in_full),
                    label: const Text('View Full'),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Summary Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: PatientMedicalQuickView(
                    patientId: patientId,
                    showFullDetails: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
