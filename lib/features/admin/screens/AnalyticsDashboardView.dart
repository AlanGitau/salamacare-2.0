import 'package:flutter/material.dart';
import 'package:signup/features/admin/admin_theme.dart';
import 'package:signup/features/admin/services/analytics_service.dart';
import 'package:signup/features/admin/widgets/stat_summary_card.dart';
import 'package:signup/features/admin/widgets/appointment_trend_chart.dart';
import 'package:signup/features/admin/widgets/doctor_performance_chart.dart';
import 'package:signup/features/admin/widgets/patient_demographics_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboardView extends StatefulWidget {
  const AnalyticsDashboardView({super.key});

  @override
  State<AnalyticsDashboardView> createState() => _AnalyticsDashboardViewState();
}

class _AnalyticsDashboardViewState extends State<AnalyticsDashboardView> {
  final _analyticsService = AnalyticsService();

  bool _isLoading = true;
  String _selectedPeriod = '30';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _appointmentTrends = [];
  List<Map<String, dynamic>> _doctorPerformance = [];
  Map<String, dynamic> _demographics = {};
  Map<String, int> _statusBreakdown = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTime get _startDate {
    if (_customStartDate != null) return _customStartDate!;
    return DateTime.now().subtract(Duration(days: int.parse(_selectedPeriod)));
  }

  DateTime get _endDate {
    if (_customEndDate != null) return _customEndDate!;
    return DateTime.now();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _analyticsService.getDashboardSummary(startDate: _startDate, endDate: _endDate),
        _analyticsService.getAppointmentTrends(startDate: _startDate, endDate: _endDate),
        _analyticsService.getDoctorPerformanceMetrics(startDate: _startDate, endDate: _endDate),
        _analyticsService.getPatientDemographics(),
        _analyticsService.getAppointmentsByStatus(startDate: _startDate, endDate: _endDate),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as Map<String, dynamic>;
          _appointmentTrends = results[1] as List<Map<String, dynamic>>;
          _doctorPerformance = results[2] as List<Map<String, dynamic>>;
          _demographics = results[3] as Map<String, dynamic>;
          _statusBreakdown = results[4] as Map<String, int>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e',
                style: adminBodyText().copyWith(color: Colors.white)),
            backgroundColor: adminDanger,
          ),
        );
      }
    }
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: adminAccent),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: adminBgCanvas,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildChartGrid(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics Dashboard', style: adminPageTitle()),
            const SizedBox(height: 2),
            Text(
              'Data from ${DateFormat('MMM d').format(_startDate)} – ${DateFormat('MMM d, yyyy').format(_endDate)}',
              style: adminBodyText(),
            ),
          ],
        ),
        const Spacer(),
        // Period selector
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: adminBgSurface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: adminBorderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPeriod == 'custom' ? null : _selectedPeriod,
              hint: Text('Custom range', style: adminBodyText()),
              style: adminBodyText(),
              dropdownColor: adminBgSurface,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: adminTextBody),
              items: const [
                DropdownMenuItem(value: '7', child: Text('Last 7 days')),
                DropdownMenuItem(value: '30', child: Text('Last 30 days')),
                DropdownMenuItem(value: '90', child: Text('Last 90 days')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPeriod = value;
                    _customStartDate = null;
                    _customEndDate = null;
                  });
                  _loadData();
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        adminSecondaryButton(
          label: 'Custom',
          icon: Icons.date_range_outlined,
          onTap: _selectCustomDateRange,
        ),
        const SizedBox(width: 8),
        adminSecondaryButton(
          label: 'Refresh',
          icon: Icons.refresh,
          onTap: _loadData,
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: StatSummaryCard(
            title: 'Total Patients',
            value: _summary['total_patients']?.toString() ?? '0',
            icon: Icons.people_outline,
            color: adminAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatSummaryCard(
            title: 'Total Doctors',
            value: _summary['total_doctors']?.toString() ?? '0',
            icon: Icons.local_hospital_outlined,
            color: adminAccent,
            subtitle: '${_summary['verified_doctors'] ?? 0} verified',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatSummaryCard(
            title: 'Appointments',
            value: _summary['total_appointments']?.toString() ?? '0',
            icon: Icons.calendar_today_outlined,
            color: adminAccent,
            subtitle: '${_summary['today_appointments'] ?? 0} today',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatSummaryCard(
            title: 'Pending Verification',
            value: _summary['pending_verification']?.toString() ?? '0',
            icon: Icons.pending_actions_outlined,
            color: adminAccent,
          ),
        ),
      ],
    );
  }

  Widget _chartCard({required String title, required Widget child, Widget? trailing}) {
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
          Row(
            children: [
              Text(title, style: adminSectionHeading()),
              if (trailing != null) ...[const Spacer(), trailing],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildChartGrid() {
    final groupBy =
        int.parse(_selectedPeriod == 'custom' ? '30' : _selectedPeriod) > 30 ? 'week' : 'day';

    return Column(
      children: [
        // Appointment trends (full width)
        _chartCard(
          title: 'Appointment Trends',
          trailing: ChartLegend(
            items: const [
              ChartLegendItem(label: 'Total', color: adminAccent),
              ChartLegendItem(label: 'Completed', color: adminSuccess),
              ChartLegendItem(label: 'Cancelled', color: adminDanger),
            ],
          ),
          child: SizedBox(
            height: 300,
            child: AppointmentTrendChart(
              appointments: _appointmentTrends,
              groupBy: groupBy,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Doctor performance + Status breakdown
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _chartCard(
                title: 'Doctor Performance',
                child: Column(
                  children: [
                    DoctorStatsSummary(performanceData: _doctorPerformance),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 250,
                      child: DoctorPerformanceChart(
                        performanceData: _doctorPerformance,
                        maxDoctors: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ChartLegend(
                      items: const [
                        ChartLegendItem(label: 'Completed', color: adminSuccess),
                        ChartLegendItem(label: 'Cancelled', color: adminDanger),
                        ChartLegendItem(label: 'No-show', color: adminWarning),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _chartCard(
                title: 'Status Breakdown',
                child: _buildStatusBreakdown(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Demographics row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _chartCard(
                title: 'Gender Distribution',
                child: SizedBox(
                  height: 250,
                  child: GenderDistributionChart(
                    genderData: Map<String, int>.from(
                      _demographics['gender_distribution'] ?? {},
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _chartCard(
                title: 'Age Distribution',
                child: SizedBox(
                  height: 250,
                  child: AgeDistributionChart(
                    ageGroupData: Map<String, int>.from(
                      _demographics['age_group_distribution'] ?? {},
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _chartCard(
                title: 'Blood Groups',
                child: SizedBox(
                  height: 250,
                  child: BloodGroupDistributionChart(
                    bloodGroupData: Map<String, int>.from(
                      _demographics['blood_group_distribution'] ?? {},
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBreakdown() {
    final total = _statusBreakdown.values.fold<int>(0, (sum, v) => sum + v);

    final statusConfig = {
      'scheduled':  {'label': 'Scheduled',  'color': adminAccent},
      'confirmed':  {'label': 'Confirmed',  'color': adminSuccess},
      'completed':  {'label': 'Completed',  'color': adminSuccess},
      'cancelled':  {'label': 'Cancelled',  'color': adminDanger},
      'no_show':    {'label': 'No Show',    'color': adminWarning},
    };

    return Column(
      children: _statusBreakdown.entries.map((entry) {
        final config = statusConfig[entry.key] ??
            {'label': entry.key, 'color': adminNeutral};
        final pct = total > 0 ? (entry.value / total * 100) : 0.0;
        final barColor = config['color'] as Color;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(config['label'] as String, style: adminBodyText()),
                  Text(
                    '${entry.value} (${pct.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: barColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: adminBorderLight,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (pct / 100).clamp(0.0, 1.0),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
