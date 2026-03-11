import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:signup/features/admin/admin_theme.dart';

/// Bar chart widget for displaying doctor performance metrics
class DoctorPerformanceChart extends StatelessWidget {
  final List<Map<String, dynamic>> performanceData;
  final int maxDoctors;

  const DoctorPerformanceChart({
    super.key,
    required this.performanceData,
    this.maxDoctors = 10,
  });

  @override
  Widget build(BuildContext context) {
    final data = performanceData.take(maxDoctors).toList();

    if (data.isEmpty) {
      return Center(
        child: Text('No data available', style: adminBodyText()),
      );
    }

    final maxY = data
        .map((d) => d['total_appointments'] as int)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final doctor = data[group.x.toInt()];
              String label;
              switch (rodIndex) {
                case 0:
                  label = 'Completed: ${doctor['completed']}';
                  break;
                case 1:
                  label = 'Cancelled: ${doctor['cancelled']}';
                  break;
                case 2:
                  label = 'No-show: ${doctor['no_show']}';
                  break;
                default:
                  label = '';
              }
              return BarTooltipItem(
                '${doctor['name']}\n$label',
                const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'DM Sans',
                    fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final name = data[index]['name'] as String;
                  final shortName =
                      name.replaceAll('Dr. ', '').split(' ').last;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: Text(
                        shortName,
                        style: adminMetadata(),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 60,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: adminMetadata(),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval:
              (maxY / 5).ceilToDouble().clamp(1, double.infinity),
          getDrawingHorizontalLine: (value) => const FlLine(
            color: adminBorderLight,
            strokeWidth: 1,
          ),
        ),
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final doctor = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: (doctor['completed'] as int).toDouble(),
                color: adminSuccess,
                width: 8,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(3)),
              ),
              BarChartRodData(
                toY: (doctor['cancelled'] as int).toDouble(),
                color: adminDanger,
                width: 8,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(3)),
              ),
              BarChartRodData(
                toY: (doctor['no_show'] as int).toDouble(),
                color: adminWarning,
                width: 8,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// Horizontal bar chart for completion rate comparison
class DoctorCompletionRateChart extends StatelessWidget {
  final List<Map<String, dynamic>> performanceData;
  final int maxDoctors;

  const DoctorCompletionRateChart({
    super.key,
    required this.performanceData,
    this.maxDoctors = 10,
  });

  @override
  Widget build(BuildContext context) {
    final data = List<Map<String, dynamic>>.from(performanceData)
      ..sort((a, b) => (b['completion_rate'] as double)
          .compareTo(a['completion_rate'] as double))
      ..take(maxDoctors);

    if (data.isEmpty) {
      return Center(
        child: Text('No data available', style: adminBodyText()),
      );
    }

    return Column(
      children: data.take(maxDoctors).map((doctor) {
        final rate = doctor['completion_rate'] as double;
        final color = rate >= 80
            ? adminSuccess
            : rate >= 60
                ? adminWarning
                : adminDanger;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  doctor['name'] as String,
                  style: adminBodyText(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: adminBgSubtle,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: adminBorderLight),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: rate / 100,
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Summary stats row for doctor performance
class DoctorStatsSummary extends StatelessWidget {
  final List<Map<String, dynamic>> performanceData;

  const DoctorStatsSummary({super.key, required this.performanceData});

  @override
  Widget build(BuildContext context) {
    if (performanceData.isEmpty) {
      return Center(
          child: Text('No data available', style: adminBodyText()));
    }

    final totalAppointments = performanceData.fold<int>(
        0, (sum, d) => sum + (d['total_appointments'] as int));
    final totalCompleted = performanceData.fold<int>(
        0, (sum, d) => sum + (d['completed'] as int));
    final totalCancelled = performanceData.fold<int>(
        0, (sum, d) => sum + (d['cancelled'] as int));
    final avgCompletionRate =
        performanceData.fold<double>(
              0,
              (sum, d) => sum + (d['completion_rate'] as double),
            ) /
            performanceData.length;

    return Row(
      children: [
        _statItem('Total Appointments', totalAppointments.toString(),
            adminAccent),
        const SizedBox(width: 12),
        _statItem('Completed', totalCompleted.toString(), adminSuccess),
        const SizedBox(width: 12),
        _statItem('Cancelled', totalCancelled.toString(), adminDanger),
        const SizedBox(width: 12),
        _statItem('Avg. Completion',
            '${avgCompletionRate.toStringAsFixed(1)}%', adminNeutral),
      ],
    );
  }

  Widget _statItem(String label, String value, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: adminBgSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: adminBorderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: adminMetadata()),
          ],
        ),
      ),
    );
  }
}
