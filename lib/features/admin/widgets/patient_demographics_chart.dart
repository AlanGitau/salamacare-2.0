import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:signup/features/admin/admin_theme.dart';

/// Pie chart widget for patient gender distribution
class GenderDistributionChart extends StatelessWidget {
  final Map<String, int> genderData;

  const GenderDistributionChart({super.key, required this.genderData});

  @override
  Widget build(BuildContext context) {
    if (genderData.isEmpty) {
      return Center(child: Text('No data available', style: adminBodyText()));
    }

    final total = genderData.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) {
      return Center(child: Text('No data available', style: adminBodyText()));
    }

    // Gender color palette — keep intentional gender-associated colors
    const colors = {
      'male': adminAccent,
      'female': Color(0xFFE879A0),
      'other': adminNeutral,
      'unknown': adminBorderLight,
    };

    final sections = genderData.entries
        .where((e) => e.value > 0)
        .map((entry) {
      final percentage = (entry.value / total * 100);
      return PieChartSectionData(
        color: colors[entry.key] ?? adminBorderLight,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        radius: 76,
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 36,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: genderData.entries
              .where((e) => e.value > 0)
              .map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors[entry.key] ?? adminBorderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_capitalize(entry.key)}: ${entry.value}',
                  style: adminMetadata(),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Pie chart widget for blood group distribution
class BloodGroupDistributionChart extends StatelessWidget {
  final Map<String, int> bloodGroupData;

  const BloodGroupDistributionChart(
      {super.key, required this.bloodGroupData});

  @override
  Widget build(BuildContext context) {
    if (bloodGroupData.isEmpty) {
      return Center(child: Text('No data available', style: adminBodyText()));
    }

    final total =
        bloodGroupData.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) {
      return Center(child: Text('No data available', style: adminBodyText()));
    }

    // Distinct flat colors for blood groups
    const colors = [
      adminDanger,
      adminAccent,
      adminSuccess,
      adminWarning,
      Color(0xFF8B5CF6), // purple
      Color(0xFF06B6D4), // cyan
      Color(0xFFF97316), // orange
      Color(0xFF6B7280), // gray
      adminBorderLight,
    ];

    final entries = bloodGroupData.entries
        .where((e) => e.value > 0 && e.key != 'unknown')
        .toList();

    final sections = entries.asMap().entries.map((mapEntry) {
      final index = mapEntry.key;
      final entry = mapEntry.value;
      final percentage = (entry.value / total * 100);
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value.toDouble(),
        title: entry.key,
        titleStyle: const TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        radius: 66,
        badgeWidget: Text(
          '${percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            fontFamily: 'IBM Plex Mono',
            fontSize: 10,
            color: colors[index % colors.length],
            fontWeight: FontWeight.w600,
          ),
        ),
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 26,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: entries.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text('${entry.key}: ${entry.value}',
                    style: adminMetadata()),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Bar chart widget for age group distribution
class AgeDistributionChart extends StatelessWidget {
  final Map<String, int> ageGroupData;

  const AgeDistributionChart({super.key, required this.ageGroupData});

  @override
  Widget build(BuildContext context) {
    if (ageGroupData.isEmpty) {
      return Center(child: Text('No data available', style: adminBodyText()));
    }

    const ageGroups = ['0-17', '18-30', '31-45', '46-60', '60+'];
    final data = ageGroups.map((g) => ageGroupData[g] ?? 0).toList();

    final maxY = data.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxY == 0) {
      return Center(child: Text('No data available', style: adminBodyText()));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${ageGroups[group.x.toInt()]}\n${rod.toY.toInt()} patients',
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
                if (index >= 0 && index < ageGroups.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(ageGroups[index], style: adminMetadata()),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: adminMetadata());
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
          getDrawingHorizontalLine: (value) => const FlLine(
            color: adminBorderLight,
            strokeWidth: 1,
          ),
        ),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: adminAccent,
                width: 22,
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

/// Combined demographics overview widget
class DemographicsOverview extends StatelessWidget {
  final Map<String, dynamic> demographics;

  const DemographicsOverview({super.key, required this.demographics});

  @override
  Widget build(BuildContext context) {
    final genderData =
        Map<String, int>.from(demographics['gender_distribution'] ?? {});
    final bloodGroupData = Map<String, int>.from(
        demographics['blood_group_distribution'] ?? {});
    final ageGroupData = Map<String, int>.from(
        demographics['age_group_distribution'] ?? {});

    return Column(
      children: [
        // Summary stats row
        Row(
          children: [
            _summaryCard(
              'Total Patients',
              demographics['total_patients']?.toString() ?? '0',
              Icons.people_outline,
            ),
            const SizedBox(width: 12),
            _summaryCard(
              'Male',
              genderData['male']?.toString() ?? '0',
              Icons.male,
            ),
            const SizedBox(width: 12),
            _summaryCard(
              'Female',
              genderData['female']?.toString() ?? '0',
              Icons.female,
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Charts row
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _chartCard(
                  'Gender Distribution',
                  GenderDistributionChart(genderData: genderData),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _chartCard(
                  'Age Distribution',
                  AgeDistributionChart(ageGroupData: ageGroupData),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: adminBgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: adminBorderLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: adminTextMuted, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: adminTextHeading,
                  ),
                ),
                Text(title, style: adminMetadata()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: adminTextHeading,
              )),
          const SizedBox(height: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}
