import 'package:flutter/material.dart';
import 'package:signup/features/admin/admin_theme.dart';
import 'package:signup/features/admin/services/analytics_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class NoShowAnalyticsView extends StatefulWidget {
  const NoShowAnalyticsView({super.key});

  @override
  State<NoShowAnalyticsView> createState() => _NoShowAnalyticsViewState();
}

class _NoShowAnalyticsViewState extends State<NoShowAnalyticsView> {
  final _analyticsService = AnalyticsService();

  bool _isLoading = true;
  String _selectedPeriod = '90';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _trendData = [];
  List<Map<String, dynamic>> _doctorBreakdown = [];
  List<Map<String, dynamic>> _dayBreakdown = [];
  List<Map<String, dynamic>> _topNoShowPatients = [];
  Map<String, dynamic> _reminderComparison = {};

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
        _analyticsService.getNoShowSummary(startDate: _startDate, endDate: _endDate),
        _analyticsService.getNoShowTrend(startDate: _startDate, endDate: _endDate),
        _analyticsService.getNoShowByDoctor(startDate: _startDate, endDate: _endDate),
        _analyticsService.getNoShowByDayOfWeek(startDate: _startDate, endDate: _endDate),
        _analyticsService.getNoShowByTimeSlot(startDate: _startDate, endDate: _endDate),
        _analyticsService.getTopNoShowPatients(startDate: _startDate, endDate: _endDate, limit: 10),
        _analyticsService.getReminderImpactComparison(),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as Map<String, dynamic>;
          _trendData = results[1] as List<Map<String, dynamic>>;
          _doctorBreakdown = results[2] as List<Map<String, dynamic>>;
          _dayBreakdown = results[3] as List<Map<String, dynamic>>;
          _topNoShowPatients = results[5] as List<Map<String, dynamic>>;
          _reminderComparison = results[6] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading no-show analytics: $e',
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: adminAccent),
        ),
        child: child!,
      ),
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
              child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildReminderImpact(),
                  const SizedBox(height: 24),
                  _buildTrendChart(),
                  const SizedBox(height: 24),
                  _buildBreakdownCharts(),
                  const SizedBox(height: 24),
                  _buildTopNoShowPatients(),
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
            Text('No-Show Analytics', style: adminPageTitle()),
            const SizedBox(height: 2),
            Text(
              '${DateFormat('MMM d, yyyy').format(_startDate)} – ${DateFormat('MMM d, yyyy').format(_endDate)}',
              style: adminBodyText(),
            ),
          ],
        ),
        const Spacer(),
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
                DropdownMenuItem(value: '30', child: Text('Last 30 Days')),
                DropdownMenuItem(value: '90', child: Text('Last 90 Days')),
                DropdownMenuItem(value: '180', child: Text('Last 180 Days')),
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
    final totalAppointments = _summary['total_appointments'] ?? 0;
    final totalNoShows = _summary['no_shows'] ?? 0;
    final noShowRate = (_summary['no_show_rate'] as num?)?.toDouble() ?? 0.0;
    final estimatedCost = (_summary['estimated_cost'] as num?)?.toDouble() ?? 0.0;

    return Row(
      children: [
        Expanded(child: _kpiCard('No-Show Rate', '${noShowRate.toStringAsFixed(1)}%',
            Icons.trending_down_outlined, subtitle: 'Target: < 15%')),
        const SizedBox(width: 16),
        Expanded(child: _kpiCard('Total No-Shows', '$totalNoShows',
            Icons.person_off_outlined, subtitle: 'of $totalAppointments appointments')),
        const SizedBox(width: 16),
        Expanded(child: _kpiCard('Late Cancellations', '${_summary['late_cancellations'] ?? 0}',
            Icons.schedule_outlined, subtitle: '<4 hours notice')),
        const SizedBox(width: 16),
        Expanded(child: _kpiCard('Estimated Cost', 'KES ${_formatCurrency(estimatedCost)}',
            Icons.attach_money_outlined, subtitle: 'Lost revenue')),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, {String? subtitle}) {
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
          Row(children: [
            Icon(icon, size: 20, color: adminAccent),
            const Spacer(),
          ]),
          const SizedBox(height: 12),
          Text(value, style: adminKpiNumber()),
          const SizedBox(height: 4),
          Row(children: [
            Text(title, style: adminBodyText()),
            if (subtitle != null) ...[
              const Spacer(),
              Text(subtitle, style: adminMetadata()),
            ],
          ]),
        ],
      ),
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
          Row(children: [
            Text(title, style: adminSectionHeading()),
            if (trailing != null) ...[const Spacer(), trailing],
          ]),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildReminderImpact() {
    final before = _reminderComparison['before'] as Map<String, dynamic>? ?? {};
    final after = _reminderComparison['after'] as Map<String, dynamic>? ?? {};
    final beforeRate = (before['rate'] as num?)?.toDouble() ?? 0.0;
    final afterRate = (after['rate'] as num?)?.toDouble() ?? 0.0;
    final improvement =
        ((_reminderComparison['improvement'])?['absolute'] as num?)?.toDouble() ?? 0.0;
    final hasData = ((before['total'] as int?) ?? 0) > 0;

    if (!hasData) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: adminAccentTint,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: adminAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: adminAccent, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reminder System Impact', style: adminSectionHeading()),
                  const SizedBox(height: 4),
                  Text(
                    'Not enough data yet. The system will compare no-show rates before and after the reminder system was implemented.',
                    style: adminBodyText(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _chartCard(
      title: 'Reminder System Impact',
      trailing: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, size: 16, color: adminAccent),
          const SizedBox(width: 6),
          Text('Impact Analysis', style: adminBodyText()),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _comparisonCell('Before Reminders', '${beforeRate.toStringAsFixed(1)}%',
              'Average no-show rate', adminDanger)),
          const SizedBox(width: 16),
          const Icon(Icons.arrow_forward, size: 20, color: adminTextMuted),
          const SizedBox(width: 16),
          Expanded(child: _comparisonCell('After Reminders', '${afterRate.toStringAsFixed(1)}%',
              'Current no-show rate', adminSuccess)),
          const SizedBox(width: 16),
          Expanded(child: _comparisonCell(
            'Improvement',
            improvement > 0 ? '${improvement.toStringAsFixed(1)}%' : 'N/A',
            improvement > 0 ? 'Reduction achieved' : 'No improvement yet',
            improvement > 0 ? adminSuccess : adminNeutral,
          )),
        ],
      ),
    );
  }

  Widget _comparisonCell(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: adminBgSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: adminBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: adminBodyText()),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: adminMetadata()),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    if (_trendData.isEmpty) return _emptyCard('No trend data available for selected period');

    final maxRate = _trendData
        .map((d) => (d['rate'] as num).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);
    final computedMaxY = ((maxRate * 1.25) / 10).ceil() * 10.0;
    final chartMaxY = computedMaxY < 10 ? 10.0 : computedMaxY;
    final labelInterval = (_trendData.length / 6).ceil().toDouble().clamp(1.0, double.infinity);

    return _chartCard(
      title: 'No-Show Rate Trend',
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: adminBorderLight, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text('${value.toInt()}%',
                      style: adminMetadata()),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: labelInterval,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= _trendData.length) return const Text('');
                    final date = DateTime.parse(_trendData[idx]['date']);
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(DateFormat('MMM d').format(date), style: adminMetadata()),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  _trendData.length,
                  (i) => FlSpot(i.toDouble(), (_trendData[i]['rate'] as num).toDouble()),
                ),
                isCurved: true,
                color: adminDanger,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
            minY: 0,
            maxY: chartMaxY,
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownCharts() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildDoctorBreakdownChart()),
        const SizedBox(width: 16),
        Expanded(child: _buildDayBreakdownChart()),
      ],
    );
  }

  Widget _buildDoctorBreakdownChart() {
    if (_doctorBreakdown.isEmpty) return _emptyCard('No doctor data available');

    final maxY = _doctorBreakdown
            .map((e) => (e['no_shows'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b) *
        1.2;

    return _chartCard(
      title: 'No-Shows by Doctor',
      child: SizedBox(
        height: 300,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) =>
                      Text('${value.toInt()}', style: adminMetadata()),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= _doctorBreakdown.length) return const Text('');
                    final name = _doctorBreakdown[value.toInt()]['name'] as String;
                    final parts = name.split(' ');
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        parts.length > 1 ? '${parts[0]} ${parts[1][0]}.' : name,
                        style: adminMetadata(),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: adminBorderLight, strokeWidth: 1),
            ),
            barGroups: List.generate(
              _doctorBreakdown.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: (_doctorBreakdown[i]['no_shows'] as num).toDouble(),
                    color: adminDanger,
                    width: 18,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayBreakdownChart() {
    if (_dayBreakdown.isEmpty) return _emptyCard('No day breakdown data available');

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxY = _dayBreakdown
            .map((e) => (e['no_shows'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b) *
        1.2;

    return _chartCard(
      title: 'No-Shows by Day of Week',
      child: SizedBox(
        height: 300,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) =>
                      Text('${value.toInt()}', style: adminMetadata()),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= _dayBreakdown.length) return const Text('');
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(days[value.toInt()], style: adminMetadata()),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: adminBorderLight, strokeWidth: 1),
            ),
            barGroups: List.generate(
              _dayBreakdown.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: (_dayBreakdown[i]['no_shows'] as num).toDouble(),
                    color: adminWarning,
                    width: 28,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopNoShowPatients() {
    if (_topNoShowPatients.isEmpty) return _emptyCard('No patient data available');

    return _chartCard(
      title: 'Top 10 No-Show Patients',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: adminDangerTint,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: adminDanger),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_outlined, size: 14, color: adminDanger),
            const SizedBox(width: 4),
            Text('High Risk Patients',
                style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: adminDanger)),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: adminBgSubtle,
              border: Border(bottom: BorderSide(color: adminBorderLight)),
            ),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('RANK', style: adminTableHeader())),
                Expanded(flex: 3, child: Text('PATIENT NAME', style: adminTableHeader())),
                Expanded(flex: 2, child: Text('NO-SHOWS', style: adminTableHeader())),
                Expanded(flex: 2, child: Text('LATE CANCELS', style: adminTableHeader())),
                Expanded(flex: 2, child: Text('RISK LEVEL', style: adminTableHeader())),
              ],
            ),
          ),
          // Data rows
          ..._topNoShowPatients.asMap().entries.map((entry) {
            final i = entry.key;
            final patient = entry.value;
            final noShowCount = (patient['no_shows'] as int?) ?? 0;
            final lateCancelCount = 0;
            final riskLevel = _getRiskLevel(noShowCount, lateCancelCount);
            final isEven = i.isEven;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isEven ? adminBgSurface : adminBgSubtle,
                border: const Border(bottom: BorderSide(color: adminBorderLight)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text('${i + 1}',
                        style: adminBodyText()
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(patient['name'] ?? 'Unknown', style: adminBodyText()),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('$noShowCount',
                        style: const TextStyle(
                            fontFamily: 'IBM Plex Mono',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: adminDanger)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('$lateCancelCount',
                        style: const TextStyle(
                            fontFamily: 'IBM Plex Mono',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: adminWarning)),
                  ),
                  Expanded(flex: 2, child: _riskBadge(riskLevel)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _riskBadge(String riskLevel) {
    Color bg, textColor, borderColor;
    switch (riskLevel) {
      case 'Critical':
        bg = adminDangerTint; textColor = adminDanger; borderColor = adminDanger;
        break;
      case 'High':
        bg = adminWarningTint; textColor = adminWarning; borderColor = adminWarning;
        break;
      default:
        bg = adminBgSubtle; textColor = adminTextBody; borderColor = adminBorderLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(riskLevel,
          style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor)),
    );
  }

  String _getRiskLevel(int noShows, int lateCancels) {
    final total = noShows + (lateCancels * 0.5).round();
    if (total >= 5) return 'Critical';
    if (total >= 3) return 'High';
    return 'Medium';
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminBorderLight),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 40, color: adminTextMuted),
            const SizedBox(height: 12),
            Text(message, style: adminBodyText()),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}
