import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:signup/features/admin/admin_theme.dart';

/// Line chart widget for displaying appointment trends over time
class AppointmentTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final String groupBy; // 'day', 'week', 'month'

  const AppointmentTrendChart({
    super.key,
    required this.appointments,
    this.groupBy = 'day',
  });

  @override
  Widget build(BuildContext context) {
    final chartData = _processData();

    if (chartData.isEmpty) {
      return Center(
        child: Text('No data available', style: adminBodyText()),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getHorizontalInterval(chartData),
          getDrawingHorizontalLine: (value) => const FlLine(
            color: adminBorderLight,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getBottomInterval(chartData),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < chartData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      chartData[index]['label'],
                      style: adminMetadata(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
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
        lineBarsData: [
          // Total appointments line
          LineChartBarData(
            spots: chartData
                .asMap()
                .entries
                .map((e) => FlSpot(
                    e.key.toDouble(),
                    (e.value['total'] as int).toDouble()))
                .toList(),
            isCurved: true,
            color: adminAccent,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: adminAccent,
                  strokeWidth: 2,
                  strokeColor: adminBgSurface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: adminAccent.withValues(alpha: 0.06),
            ),
          ),
          // Completed appointments line
          LineChartBarData(
            spots: chartData
                .asMap()
                .entries
                .map((e) => FlSpot(
                    e.key.toDouble(),
                    (e.value['completed'] as int).toDouble()))
                .toList(),
            isCurved: true,
            color: adminSuccess,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Cancelled appointments line
          LineChartBarData(
            spots: chartData
                .asMap()
                .entries
                .map((e) => FlSpot(
                    e.key.toDouble(),
                    (e.value['cancelled'] as int).toDouble()))
                .toList(),
            isCurved: true,
            color: adminDanger,
            barWidth: 2,
            isStrokeCapRound: true,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dataIndex = spot.x.toInt();
                if (dataIndex < chartData.length) {
                  final data = chartData[dataIndex];
                  String label;
                  Color color;
                  if (spot.barIndex == 0) {
                    label = 'Total: ${data['total']}';
                    color = adminAccent;
                  } else if (spot.barIndex == 1) {
                    label = 'Completed: ${data['completed']}';
                    color = adminSuccess;
                  } else {
                    label = 'Cancelled: ${data['cancelled']}';
                    color = adminDanger;
                  }
                  return LineTooltipItem(
                    label,
                    TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'DM Sans',
                        fontSize: 12),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _processData() {
    if (appointments.isEmpty) return [];

    final grouped = <String, Map<String, int>>{};

    for (var appointment in appointments) {
      final date = DateTime.parse(appointment['appointment_date']);
      String key;

      switch (groupBy) {
        case 'month':
          key = DateFormat('MMM yy').format(date);
          break;
        case 'week':
          final weekStart =
              date.subtract(Duration(days: date.weekday - 1));
          key = DateFormat('MMM d').format(weekStart);
          break;
        default: // day
          key = DateFormat('MMM d').format(date);
      }

      grouped.putIfAbsent(key, () => {
            'total': 0,
            'completed': 0,
            'cancelled': 0,
            'no_show': 0,
          });

      grouped[key]!['total'] = grouped[key]!['total']! + 1;

      final status = appointment['status'];
      if (status == 'completed') {
        grouped[key]!['completed'] = grouped[key]!['completed']! + 1;
      } else if (status == 'cancelled') {
        grouped[key]!['cancelled'] = grouped[key]!['cancelled']! + 1;
      } else if (status == 'no_show') {
        grouped[key]!['no_show'] = grouped[key]!['no_show']! + 1;
      }
    }

    return grouped.entries
        .map((e) => {'label': e.key, ...e.value})
        .toList();
  }

  double _getHorizontalInterval(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 1;
    final maxValue = data
        .map((d) => d['total'] as int)
        .reduce((a, b) => a > b ? a : b);
    return (maxValue / 5).ceilToDouble().clamp(1, double.infinity);
  }

  double _getBottomInterval(List<Map<String, dynamic>> data) {
    if (data.length <= 7) return 1;
    return (data.length / 7).ceilToDouble();
  }
}

/// Chart legend widget
class ChartLegend extends StatelessWidget {
  final List<ChartLegendItem> items;

  const ChartLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items
          .map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(item.label, style: adminMetadata()),
                ],
              ))
          .toList(),
    );
  }
}

class ChartLegendItem {
  final String label;
  final Color color;

  const ChartLegendItem({required this.label, required this.color});
}
