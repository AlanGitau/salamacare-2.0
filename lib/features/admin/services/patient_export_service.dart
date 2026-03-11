import 'package:flutter/material.dart' show BuildContext;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PatientExportService {
  Future<void> generatePatientPdf(
    Map<String, dynamic> patient,
    BuildContext? context,
  ) async {
    final pdf = pw.Document();
    final name = '${patient['first_name']} ${patient['last_name']}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Patient Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text('SalamaCare', style: pw.TextStyle(fontSize: 16, color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Generated: ${DateFormat('MMM dd, yyyy - h:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(color: PdfColors.grey600)),
          pw.SizedBox(height: 20),

          // Personal Info
          _buildPdfSection('Personal Information', [
            _buildPdfRow('Name', name),
            _buildPdfRow('Email', patient['users']?['email'] ?? 'N/A'),
            _buildPdfRow('Phone', patient['phone'] ?? 'N/A'),
            _buildPdfRow('Date of Birth', patient['date_of_birth'] ?? 'N/A'),
            _buildPdfRow('Gender', (patient['gender'] ?? 'N/A').toString().toUpperCase()),
            _buildPdfRow('Blood Group', patient['blood_group'] ?? 'N/A'),
            _buildPdfRow('Address', patient['address'] ?? 'N/A'),
          ]),

          pw.SizedBox(height: 16),

          // Medical Info
          _buildPdfSection('Medical Information', [
            _buildPdfRow('Allergies', patient['allergies'] ?? 'None'),
            _buildPdfRow('Chronic Conditions', patient['chronic_conditions'] ?? 'None'),
            _buildPdfRow('Current Medications', patient['current_medications'] ?? 'None'),
            _buildPdfRow('Medical History', patient['medical_history'] ?? 'None'),
          ]),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'patient_${name.replaceAll(' ', '_')}.pdf',
    );
  }

  Future<void> generatePatientListPdf(List<Map<String, dynamic>> patients) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Patient List Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text('SalamaCare', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.Text('Generated: ${DateFormat('MMM dd, yyyy').format(DateTime.now())} | Total: ${patients.length} patients',
              style: const pw.TextStyle(color: PdfColors.grey600)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellPadding: const pw.EdgeInsets.all(4),
            headers: ['Name', 'Email', 'Phone', 'DOB', 'Gender', 'Blood Group', 'Allergies'],
            data: patients.map((p) => [
              '${p['first_name']} ${p['last_name']}',
              p['users']?['email'] ?? '',
              p['phone'] ?? '',
              p['date_of_birth'] ?? '',
              (p['gender'] ?? '').toString().toUpperCase(),
              p['blood_group'] ?? '',
              p['allergies'] ?? 'None',
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'patients_list_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  pw.Widget _buildPdfSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          child: pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Column(children: children),
        ),
      ],
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 140, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }
}
