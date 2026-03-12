import 'package:flutter/material.dart';
import 'package:signup/core/constants/colors.dart';

class QuickStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isLoading;
  final VoidCallback? onTapToday;

  const QuickStatsCard({
    super.key,
    required this.stats,
    this.isLoading = false,
    this.onTapToday,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();

    final todayTotal = stats['today_total'] as int? ?? 0;
    final todayCompleted = stats['today_completed'] as int? ?? 0;
    final weekTotal = stats['week_total'] as int? ?? 0;
    final weekCompleted = stats['week_completed'] as int? ?? 0;
    final noShowRate = stats['no_show_rate'] as int? ?? 0;
    final cancellationRate = stats['cancellation_rate'] as int? ?? 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.insights, color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Quick Stats',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 300 ? 2 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.0,
                  children: [
                    _buildStatTile(
                      icon: Icons.today,
                      label: 'Today',
                      value: '$todayCompleted / $todayTotal',
                      subtitle: 'completed',
                      color: AppColors.primary,
                      onTap: onTapToday,
                    ),
                    _buildStatTile(
                      icon: Icons.date_range,
                      label: 'This Week',
                      value: '$weekCompleted / $weekTotal',
                      subtitle: 'completed',
                      color: AppColors.secondary,
                    ),
                    _buildStatTile(
                      icon: Icons.person_off_outlined,
                      label: 'No-Shows',
                      value: '$noShowRate%',
                      subtitle: 'this month',
                      color: noShowRate > 10 ? Colors.red : Colors.orange,
                    ),
                    _buildStatTile(
                      icon: Icons.event_busy,
                      label: 'Cancelled',
                      value: '$cancellationRate%',
                      subtitle: 'this month',
                      color: cancellationRate > 15 ? Colors.red : Colors.amber.shade700,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 100, height: 16, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.0,
                children: List.generate(4, (_) => Container(
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
