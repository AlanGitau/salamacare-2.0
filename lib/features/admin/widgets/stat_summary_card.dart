import 'package:flutter/material.dart';
import 'package:signup/features/admin/admin_theme.dart';

/// Flat KPI card — follows the admin design system (no shadow, no gradient,
/// no coloured icon box behind the icon). Fonts loaded from bundled assets.
class StatSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  /// Kept for API compatibility — ignored, all icons use adminAccent.
  final Color? color;

  final String? subtitle;
  final String? trend;
  final bool? isTrendPositive;
  final VoidCallback? onTap;

  const StatSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.trend,
    this.isTrendPositive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: adminBgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: adminBorderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: adminAccent),
                  const Spacer(),
                  if (trend != null)
                    _trendChip(trend!, isTrendPositive ?? true),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: adminKpiNumber()),
              const SizedBox(height: 4),
              Text(title, style: adminBodyText()),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: adminTextMuted)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _trendChip(String label, bool positive) {
    final trendColor = positive ? adminSuccess : adminDanger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(positive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12, color: trendColor),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: trendColor)),
      ],
    );
  }
}

/// Compact horizontal stat card for dense layouts.
class MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  /// Kept for API compatibility — ignored.
  final Color? color;

  const MiniStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminBorderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: adminAccent, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'IBM Plex Mono',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: adminTextHeading)),
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: adminTextBody)),
            ],
          ),
        ],
      ),
    );
  }
}
