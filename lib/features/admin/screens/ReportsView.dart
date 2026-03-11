import 'package:flutter/material.dart';
import 'package:signup/features/admin/admin_theme.dart';
import 'package:signup/features/admin/services/report_service.dart';
import 'package:signup/features/admin/services/pdf_report_service.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final _reportService = ReportService();
  final _pdfService = PdfReportService();

  bool _isLoading = false;
  bool _isGenerating = false;

  String _selectedReportType = 'appointments';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStatus;
  String? _selectedDoctorId;

  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _reportData = [];
  List<Map<String, dynamic>> _savedReports = [];

  final _reportTypes = [
    {'value': 'appointments', 'label': 'Appointment Report', 'icon': Icons.calendar_today_outlined},
    {'value': 'doctor_performance', 'label': 'Doctor Performance', 'icon': Icons.local_hospital_outlined},
    {'value': 'patient_statistics', 'label': 'Patient Statistics', 'icon': Icons.people_outline},
    {'value': 'revenue', 'label': 'Revenue Report', 'icon': Icons.attach_money_outlined},
  ];

  final _statusOptions = [
    {'value': null, 'label': 'All Statuses'},
    {'value': 'scheduled', 'label': 'Scheduled'},
    {'value': 'confirmed', 'label': 'Confirmed'},
    {'value': 'completed', 'label': 'Completed'},
    {'value': 'cancelled', 'label': 'Cancelled'},
    {'value': 'no_show', 'label': 'No Show'},
  ];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
    _loadDoctors();
    _loadSavedReports();
  }

  Future<void> _loadDoctors() async {
    final doctors = await _reportService.getDoctorsForFilter();
    if (mounted) setState(() => _doctors = doctors);
  }

  Future<void> _loadSavedReports() async {
    final reports = await _reportService.getSavedReports();
    if (mounted) setState(() => _savedReports = reports);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: adminAccent),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _reportData = [];
    });

    try {
      List<Map<String, dynamic>> data;

      switch (_selectedReportType) {
        case 'appointments':
          data = await _reportService.getAppointmentReportData(
            startDate: _startDate,
            endDate: _endDate,
            status: _selectedStatus,
            doctorId: _selectedDoctorId,
          );
          break;
        case 'doctor_performance':
          data = await _reportService.getDoctorPerformanceReportData(
            startDate: _startDate,
            endDate: _endDate,
          );
          break;
        case 'patient_statistics':
          final stats = await _reportService.getPatientStatisticsReportData();
          data = [stats];
          break;
        case 'revenue':
          final revenue = await _reportService.getRevenueReportData(
            startDate: _startDate,
            endDate: _endDate,
          );
          data = [revenue];
          break;
        default:
          data = [];
      }

      if (mounted) {
        setState(() {
          _reportData = data;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e',
                style: adminBodyText().copyWith(color: Colors.white)),
            backgroundColor: adminDanger,
          ),
        );
      }
    }
  }

  Future<void> _exportToCsv() async {
    if (_reportData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No data to export', style: adminBodyText().copyWith(color: Colors.white)),
          backgroundColor: adminNeutral,
        ),
      );
      return;
    }

    try {
      List<List<dynamic>> rows = [];

      switch (_selectedReportType) {
        case 'appointments':
          rows.add(['Patient Name', 'Doctor Name', 'Date', 'Time', 'Status', 'Reason']);
          for (var appointment in _reportData) {
            final patient = appointment['patients'];
            final doctor = appointment['doctors'];
            final date = DateTime.parse(appointment['appointment_date']);
            rows.add([
              '${patient?['first_name'] ?? ''} ${patient?['last_name'] ?? ''}',
              'Dr. ${doctor?['first_name'] ?? ''} ${doctor?['last_name'] ?? ''}',
              DateFormat('yyyy-MM-dd').format(date),
              DateFormat('HH:mm').format(date),
              appointment['status'] ?? '',
              appointment['patient_notes'] ?? '',
            ]);
          }
          break;

        case 'doctor_performance':
          rows.add(['Doctor Name', 'Specialty', 'Total', 'Completed', 'Cancelled', 'No Show', 'Rate', 'Revenue']);
          for (var doctor in _reportData) {
            rows.add([
              doctor['doctor_name'],
              doctor['specialty'],
              doctor['total_appointments'],
              doctor['completed'],
              doctor['cancelled'],
              doctor['no_show'],
              '${doctor['completion_rate']}%',
              'KES ${doctor['revenue']}',
            ]);
          }
          break;

        case 'patient_statistics':
          if (_reportData.isNotEmpty) {
            final stats = _reportData.first;
            rows.add(['Metric', 'Value']);
            rows.add(['Total Patients', stats['total_patients']]);
            rows.add(['New This Month', stats['new_patients_this_month']]);
            rows.add(['Total No-Shows', stats['total_no_shows']]);
            Map<String, int>.from(stats['gender_distribution'] ?? {})
                .forEach((k, v) => rows.add(['Gender: $k', v]));
            Map<String, int>.from(stats['age_distribution'] ?? {})
                .forEach((k, v) => rows.add(['Age Group: $k', v]));
          }
          break;

        case 'revenue':
          if (_reportData.isNotEmpty) {
            final revenue = _reportData.first;
            rows.add(['Metric', 'Value']);
            rows.add(['Total Revenue', 'KES ${revenue['total_revenue']}']);
            rows.add(['Total Appointments', revenue['total_appointments']]);
            rows.add(['Average per Appointment', 'KES ${(revenue['average_per_appointment'] as num).toStringAsFixed(2)}']);
            rows.add([]);
            rows.add(['Revenue by Doctor', '']);
            Map<String, double>.from(revenue['revenue_by_doctor'] ?? {})
                .forEach((k, v) => rows.add([k, 'KES ${v.toStringAsFixed(2)}']));
            rows.add([]);
            rows.add(['Revenue by Month', '']);
            Map<String, double>.from(revenue['revenue_by_month'] ?? {})
                .forEach((k, v) => rows.add([k, 'KES ${v.toStringAsFixed(2)}']));
          }
          break;
      }

      final csv = const ListToCsvConverter().convert(rows);

      if (!kIsWeb) {
        final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final fileName = '${_selectedReportType}_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
        final path = '${directory.path}/$fileName';
        await File(path).writeAsString(csv);

        await _reportService.saveReportRecord(
          reportType: _selectedReportType,
          reportName: fileName,
          parameters: {
            'start_date': _startDate?.toIso8601String(),
            'end_date': _endDate?.toIso8601String(),
            'status': _selectedStatus,
            'doctor_id': _selectedDoctorId,
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report exported to: $path',
                  style: adminBodyText().copyWith(color: Colors.white)),
              backgroundColor: adminSuccess,
              duration: const Duration(seconds: 5),
            ),
          );
          _loadSavedReports();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e',
                style: adminBodyText().copyWith(color: Colors.white)),
            backgroundColor: adminDanger,
          ),
        );
      }
    }
  }

  Future<void> _exportToPdf() async {
    if (_reportData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No data to export. Generate a report first.',
              style: adminBodyText().copyWith(color: Colors.white)),
          backgroundColor: adminNeutral,
        ),
      );
      return;
    }

    try {
      switch (_selectedReportType) {
        case 'appointments':
          await _pdfService.generateAppointmentReportPdf(
              data: _reportData, startDate: _startDate, endDate: _endDate);
          break;
        case 'doctor_performance':
          await _pdfService.generateDoctorPerformanceReportPdf(
              data: _reportData, startDate: _startDate, endDate: _endDate);
          break;
        case 'patient_statistics':
          if (_reportData.isNotEmpty) {
            await _pdfService.generatePatientStatisticsReportPdf(stats: _reportData.first);
          }
          break;
        case 'revenue':
          if (_reportData.isNotEmpty) {
            await _pdfService.generateRevenueReportPdf(
                revenue: _reportData.first, startDate: _startDate, endDate: _endDate);
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF export failed: $e',
                style: adminBodyText().copyWith(color: Colors.white)),
            backgroundColor: adminDanger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: adminBgCanvas,
      child: Row(
        children: [
          // Left panel — report configuration
          Container(
            width: 300,
            decoration: const BoxDecoration(
              color: adminBgSurface,
              border: Border(right: BorderSide(color: adminBorderLight)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Generate Report', style: adminSectionHeading()),
                const SizedBox(height: 20),
                _buildReportTypeSelector(),
                const SizedBox(height: 16),
                _buildDateRangeSelector(),
                if (_selectedReportType == 'appointments') ...[
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Status Filter',
                    value: _selectedStatus,
                    items: _statusOptions
                        .map((s) => DropdownMenuItem<String>(
                              value: s['value'],
                              child: Text(s['label'] as String, style: adminBodyText()),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedStatus = v),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField<String>(
                    label: 'Doctor Filter',
                    value: _selectedDoctorId,
                    items: [
                      DropdownMenuItem<String>(
                          value: null, child: Text('All Doctors', style: adminBodyText())),
                      ..._doctors.map((d) => DropdownMenuItem<String>(
                            value: d['id'] as String,
                            child: Text('Dr. ${d['first_name']} ${d['last_name']}',
                                style: adminBodyText()),
                          )),
                    ],
                    onChanged: (v) => setState(() => _selectedDoctorId = v),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: _isGenerating ? null : _generateReport,
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: _isGenerating ? adminBorderLight : adminAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isGenerating)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            const Icon(Icons.play_arrow_outlined, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            _isGenerating ? 'Generating...' : 'Generate Report',
                            style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: adminBorderLight),
                const SizedBox(height: 16),
                Text('Recent Reports', style: adminBodyText().copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Expanded(
                  child: _savedReports.isEmpty
                      ? Center(child: Text('No saved reports', style: adminBodyText()))
                      : ListView.builder(
                          itemCount: _savedReports.take(5).length,
                          itemBuilder: (context, index) {
                            final report = _savedReports[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(_getReportIcon(report['report_type']),
                                      size: 16, color: adminAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          report['report_name'] ?? 'Untitled',
                                          style: adminBodyText(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(
                                              DateTime.parse(report['created_at'])),
                                          style: adminMetadata(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Right panel — report preview
          Expanded(child: _buildReportPreview()),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Report Type',
            style: adminBodyText().copyWith(fontWeight: FontWeight.w600, color: adminTextHeading)),
        const SizedBox(height: 8),
        ..._reportTypes.map((type) {
          final isSelected = _selectedReportType == type['value'];
          return GestureDetector(
            onTap: () => setState(() {
              _selectedReportType = type['value'] as String;
              _reportData = [];
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? adminAccentTint : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: isSelected ? adminAccent.withValues(alpha: 0.4) : Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(type['icon'] as IconData,
                      size: 16,
                      color: isSelected ? adminAccent : adminTextBody),
                  const SizedBox(width: 10),
                  Text(type['label'] as String,
                      style: adminBodyText().copyWith(
                        color: isSelected ? adminAccent : adminTextBody,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      )),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date Range',
            style: adminBodyText().copyWith(fontWeight: FontWeight.w600, color: adminTextHeading)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: adminBgSubtle,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: adminBorderLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range_outlined, size: 16, color: adminTextBody),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${DateFormat('MMM dd').format(_startDate!)} – ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                    style: adminBodyText(),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: adminTextBody),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: adminBodyText().copyWith(fontWeight: FontWeight.w600, color: adminTextHeading)),
        const SizedBox(height: 8),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: adminBgSubtle,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: adminBorderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              style: adminBodyText(),
              dropdownColor: adminBgSurface,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: adminTextBody),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportPreview() {
    if (_isGenerating) {
      return const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent));
    }

    if (_reportData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assessment_outlined, size: 64, color: adminTextMuted),
            const SizedBox(height: 16),
            Text('Select report options and click Generate',
                style: adminBodyText()),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Preview header bar
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: adminBgSurface,
            border: Border(bottom: BorderSide(color: adminBorderLight)),
          ),
          child: Row(
            children: [
              Text(
                _reportTypes.firstWhere((t) => t['value'] == _selectedReportType)['label'] as String,
                style: adminSectionHeading(),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: adminBgSubtle,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: adminBorderLight),
                ),
                child: Text(
                  '${_reportData.length} ${_selectedReportType == 'patient_statistics' || _selectedReportType == 'revenue' ? 'summary' : 'records'}',
                  style: adminMetadata(),
                ),
              ),
              const Spacer(),
              adminSecondaryButton(
                label: 'Export CSV',
                icon: Icons.download_outlined,
                onTap: _exportToCsv,
              ),
              const SizedBox(width: 8),
              adminPrimaryButton(
                label: 'Export PDF',
                icon: Icons.picture_as_pdf_outlined,
                onTap: _exportToPdf,
              ),
            ],
          ),
        ),
        // Report content
        Expanded(child: _buildReportContent()),
      ],
    );
  }

  Widget _buildReportContent() {
    switch (_selectedReportType) {
      case 'appointments':
        return _buildAppointmentsTable();
      case 'doctor_performance':
        return _buildDoctorPerformanceTable();
      case 'patient_statistics':
        return _buildPatientStatisticsView();
      case 'revenue':
        return _buildRevenueView();
      default:
        return const SizedBox();
    }
  }

  Widget _buildAppointmentsTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: adminBgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: adminBorderLight),
        ),
        child: Column(
          children: [
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: adminBgSubtle,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                border: Border(bottom: BorderSide(color: adminBorderLight)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('PATIENT', style: adminTableHeader())),
                  Expanded(flex: 2, child: Text('DOCTOR', style: adminTableHeader())),
                  Expanded(flex: 2, child: Text('DATE', style: adminTableHeader())),
                  SizedBox(width: 80, child: Text('TIME', style: adminTableHeader())),
                  SizedBox(width: 100, child: Text('STATUS', style: adminTableHeader())),
                ],
              ),
            ),
            ..._reportData.asMap().entries.map((entry) {
              final i = entry.key;
              final appt = entry.value;
              final patient = appt['patients'];
              final doctor = appt['doctors'];
              final date = DateTime.parse(appt['appointment_date']);
              final status = appt['status'] ?? 'scheduled';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: i.isEven ? adminBgSurface : adminBgSubtle,
                  border: const Border(bottom: BorderSide(color: adminBorderLight)),
                ),
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text(
                            '${patient?['first_name'] ?? ''} ${patient?['last_name'] ?? ''}',
                            style: adminBodyText())),
                    Expanded(
                        flex: 2,
                        child: Text(
                            'Dr. ${doctor?['first_name'] ?? ''} ${doctor?['last_name'] ?? ''}',
                            style: adminBodyText())),
                    Expanded(
                        flex: 2,
                        child: Text(DateFormat('MMM dd, yyyy').format(date), style: adminMetadata())),
                    SizedBox(
                        width: 80,
                        child: Text(DateFormat('h:mm a').format(date), style: adminMetadata())),
                    SizedBox(width: 100, child: adminStatusBadge(status)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorPerformanceTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: adminBgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: adminBorderLight),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: adminBgSubtle,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                border: Border(bottom: BorderSide(color: adminBorderLight)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('DOCTOR', style: adminTableHeader())),
                  Expanded(flex: 2, child: Text('SPECIALTY', style: adminTableHeader())),
                  SizedBox(width: 70, child: Text('TOTAL', style: adminTableHeader())),
                  SizedBox(width: 90, child: Text('COMPLETED', style: adminTableHeader())),
                  SizedBox(width: 80, child: Text('RATE', style: adminTableHeader())),
                  SizedBox(width: 100, child: Text('REVENUE', style: adminTableHeader())),
                ],
              ),
            ),
            ..._reportData.asMap().entries.map((entry) {
              final i = entry.key;
              final doc = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: i.isEven ? adminBgSurface : adminBgSubtle,
                  border: const Border(bottom: BorderSide(color: adminBorderLight)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(doc['doctor_name'], style: adminBodyText())),
                    Expanded(flex: 2, child: Text(doc['specialty'], style: adminBodyText())),
                    SizedBox(
                        width: 70,
                        child: Text('${doc['total_appointments']}', style: adminMetadata())),
                    SizedBox(width: 90, child: Text('${doc['completed']}', style: adminMetadata())),
                    SizedBox(
                        width: 80,
                        child: Text('${doc['completion_rate']}%',
                            style: adminMetadata().copyWith(color: adminSuccess))),
                    SizedBox(
                        width: 100,
                        child: Text('KES ${doc['revenue'].toStringAsFixed(0)}',
                            style: adminMetadata())),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientStatisticsView() {
    if (_reportData.isEmpty) return const SizedBox();
    final stats = _reportData.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _reportKpiCard('Total Patients', '${stats['total_patients'] ?? 0}', Icons.people_outline)),
              const SizedBox(width: 16),
              Expanded(child: _reportKpiCard('New This Month', '${stats['new_patients_this_month'] ?? 0}', Icons.person_add_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _reportKpiCard('Total No-Shows', '${stats['total_no_shows'] ?? 0}', Icons.person_off_outlined)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _distributionCard('Gender Distribution', Map<String, int>.from(stats['gender_distribution'] ?? {}))),
              const SizedBox(width: 16),
              Expanded(child: _distributionCard('Age Distribution', Map<String, int>.from(stats['age_distribution'] ?? {}))),
              const SizedBox(width: 16),
              Expanded(child: _distributionCard('Blood Groups', Map<String, int>.from(stats['blood_group_distribution'] ?? {}))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueView() {
    if (_reportData.isEmpty) return const SizedBox();
    final revenue = _reportData.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _reportKpiCard('Total Revenue', 'KES ${(revenue['total_revenue'] ?? 0).toStringAsFixed(0)}', Icons.attach_money_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _reportKpiCard('Total Appointments', '${revenue['total_appointments'] ?? 0}', Icons.calendar_today_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _reportKpiCard('Average per Visit', 'KES ${((revenue['average_per_appointment'] ?? 0) as num).toStringAsFixed(0)}', Icons.trending_up_outlined)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _revenueByCard('Revenue by Doctor', Map<String, double>.from(revenue['revenue_by_doctor'] ?? {}))),
              const SizedBox(width: 16),
              Expanded(child: _revenueByCard('Revenue by Month', Map<String, double>.from(revenue['revenue_by_month'] ?? {}))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reportKpiCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 20, color: adminAccent), const Spacer()]),
          const SizedBox(height: 12),
          Text(value, style: adminKpiNumber()),
          const SizedBox(height: 4),
          Text(title, style: adminBodyText()),
        ],
      ),
    );
  }

  Widget _distributionCard(String title, Map<String, int> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: adminSectionHeading()),
          const SizedBox(height: 16),
          ...data.entries.where((e) => e.key != 'unknown' && e.value > 0).map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: adminBodyText()),
                  Text('${entry.value}',
                      style: adminBodyText().copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _revenueByCard(String title, Map<String, double> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: adminSectionHeading()),
          const SizedBox(height: 16),
          ...data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(entry.key,
                          style: adminBodyText(), overflow: TextOverflow.ellipsis)),
                  Text('KES ${entry.value.toStringAsFixed(0)}',
                      style: adminBodyText().copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getReportIcon(String? type) {
    switch (type) {
      case 'appointments': return Icons.calendar_today_outlined;
      case 'doctor_performance': return Icons.local_hospital_outlined;
      case 'patient_statistics': return Icons.people_outline;
      case 'revenue': return Icons.attach_money_outlined;
      default: return Icons.description_outlined;
    }
  }
}
