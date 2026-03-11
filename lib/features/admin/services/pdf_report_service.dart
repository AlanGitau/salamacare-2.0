import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfReportService {
  // ── Appointment Report PDF ──────────────────────────────────────────
  Future<void> generateAppointmentReportPdf({
    required List<Map<String, dynamic>> data,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (context) => _buildHeader(
          'Appointment Report',
          startDate: startDate,
          endDate: endDate,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
            cellHeight: 28,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.centerLeft,
            },
            headers: ['Patient', 'Doctor', 'Date', 'Time', 'Status', 'Reason'],
            data: data.map((a) {
              final patient = a['patients'];
              final doctor = a['doctors'];
              final date = DateTime.parse(a['appointment_date']);
              return [
                '${patient?['first_name'] ?? ''} ${patient?['last_name'] ?? ''}',
                'Dr. ${doctor?['first_name'] ?? ''} ${doctor?['last_name'] ?? ''}',
                DateFormat('MMM dd, yyyy').format(date),
                DateFormat('h:mm a').format(date),
                (a['status'] ?? 'scheduled').toString().toUpperCase(),
                a['patient_notes'] ?? '',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Total Records: ${data.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // ── Doctor Performance Report PDF ───────────────────────────────────
  Future<void> generateDoctorPerformanceReportPdf({
    required List<Map<String, dynamic>> data,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (context) => _buildHeader(
          'Doctor Performance Report',
          startDate: startDate,
          endDate: endDate,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
            cellHeight: 28,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
              7: pw.Alignment.centerRight,
            },
            headers: ['Doctor', 'Specialty', 'Total', 'Completed', 'Cancelled', 'No Show', 'Rate', 'Revenue'],
            data: data.map((d) => [
              d['doctor_name'] ?? '',
              d['specialty'] ?? '',
              '${d['total_appointments'] ?? 0}',
              '${d['completed'] ?? 0}',
              '${d['cancelled'] ?? 0}',
              '${d['no_show'] ?? 0}',
              '${d['completion_rate'] ?? 0}%',
              'KES ${(d['revenue'] ?? 0).toStringAsFixed(0)}',
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // ── Patient Statistics Report PDF ───────────────────────────────────
  Future<void> generatePatientStatisticsReportPdf({
    required Map<String, dynamic> stats,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader('Patient Statistics Report'),
        footer: (context) => _buildFooter(context),
        build: (context) {
          final widgets = <pw.Widget>[];

          // Summary cards
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildPdfStatCard('Total Patients', '${stats['total_patients'] ?? 0}'),
                _buildPdfStatCard('New This Month', '${stats['new_patients_this_month'] ?? 0}'),
                _buildPdfStatCard('Total No-Shows', '${stats['total_no_shows'] ?? 0}'),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 24));

          // Gender distribution
          final genderDist = Map<String, int>.from(stats['gender_distribution'] ?? {});
          if (genderDist.isNotEmpty) {
            widgets.add(_buildDistributionTable('Gender Distribution', genderDist));
            widgets.add(pw.SizedBox(height: 16));
          }

          // Age distribution
          final ageDist = Map<String, int>.from(stats['age_distribution'] ?? {});
          if (ageDist.isNotEmpty) {
            widgets.add(_buildDistributionTable('Age Distribution', ageDist));
            widgets.add(pw.SizedBox(height: 16));
          }

          // Blood group distribution
          final bloodDist = Map<String, int>.from(stats['blood_group_distribution'] ?? {});
          if (bloodDist.isNotEmpty) {
            widgets.add(_buildDistributionTable('Blood Group Distribution', bloodDist));
          }

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // ── Revenue Report PDF ──────────────────────────────────────────────
  Future<void> generateRevenueReportPdf({
    required Map<String, dynamic> revenue,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(
          'Revenue Report',
          startDate: startDate,
          endDate: endDate,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) {
          final widgets = <pw.Widget>[];

          // Summary
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildPdfStatCard('Total Revenue', 'KES ${(revenue['total_revenue'] ?? 0).toStringAsFixed(0)}'),
                _buildPdfStatCard('Total Appointments', '${revenue['total_appointments'] ?? 0}'),
                _buildPdfStatCard('Avg per Visit', 'KES ${((revenue['average_per_appointment'] ?? 0) as num).toStringAsFixed(0)}'),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 24));

          // Revenue by doctor
          final byDoctor = Map<String, double>.from(revenue['revenue_by_doctor'] ?? {});
          if (byDoctor.isNotEmpty) {
            widgets.add(
              pw.Text('Revenue by Doctor', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            );
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green50),
                headers: ['Doctor', 'Revenue'],
                data: byDoctor.entries.map((e) => [e.key, 'KES ${e.value.toStringAsFixed(0)}']).toList(),
              ),
            );
            widgets.add(pw.SizedBox(height: 16));
          }

          // Revenue by month
          final byMonth = Map<String, double>.from(revenue['revenue_by_month'] ?? {});
          if (byMonth.isNotEmpty) {
            widgets.add(
              pw.Text('Revenue by Month', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            );
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green50),
                headers: ['Month', 'Revenue'],
                data: byMonth.entries.map((e) => [e.key, 'KES ${e.value.toStringAsFixed(0)}']).toList(),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // ── Helper widgets ──────────────────────────────────────────────────

  pw.Widget _buildHeader(String title, {DateTime? startDate, DateTime? endDate}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'SalamaCare',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700),
            ),
            pw.Text(
              'Generated: ${DateFormat('MMM dd, yyyy h:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        if (startDate != null && endDate != null)
          pw.Text(
            'Period: ${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        pw.Divider(),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      ),
    );
  }

  pw.Widget _buildPdfStatCard(String label, String value) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildDistributionTable(String title, Map<String, int> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
          headers: ['Category', 'Count'],
          data: data.entries
              .where((e) => e.key != 'unknown' && e.value > 0)
              .map((e) => [e.key, '${e.value}'])
              .toList(),
        ),
      ],
    );
  }
}
