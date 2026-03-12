import 'package:flutter/material.dart';
import 'package:signup/core/constants/colors.dart';
import 'package:signup/core/services/app_notification_service.dart';
import 'package:signup/features/notifications/screens/NotificationsScreen.dart';

class NotificationPanel extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const NotificationPanel({
    super.key,
    required this.notifications,
    this.unreadCount = 0,
    this.isLoading = false,
    this.onRefresh,
  });

  static const Map<String, IconData> _typeIcons = {
    'new_booking': Icons.calendar_today,
    'booking': Icons.calendar_today,
    'cancellation': Icons.event_busy,
    'reschedule': Icons.schedule_send,
    'status_change': Icons.swap_horiz,
    'reminder': Icons.notifications_active,
    'check_in': Icons.how_to_reg,
  };

  static const Map<String, Color> _typeColors = {
    'new_booking': Color(0xFF42A5F5),
    'booking': Color(0xFF42A5F5),
    'cancellation': Color(0xFFEF5350),
    'reschedule': Color(0xFFFFA726),
    'status_change': Color(0xFF66BB6A),
    'reminder': Color(0xFF7E57C2),
    'check_in': Color(0xFF26A69A),
  };

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();

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
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_outlined, color: Colors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (notifications.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => Divider(height: 1, indent: 60, color: Colors.grey.shade100),
              itemBuilder: (context, index) => _buildNotificationItem(context, notifications[index]),
            ),
          if (notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                  child: const Text(
                    'View All Notifications',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, Map<String, dynamic> notification) {
    final title = notification['title'] as String? ?? 'Notification';
    final message = notification['message'] as String? ?? '';
    final type = notification['type'] as String? ?? 'reminder';
    final isRead = notification['is_read'] as bool? ?? false;
    final createdAt = notification['created_at'] as String?;
    final notificationId = notification['id'] as String?;

    final icon = _typeIcons[type] ?? Icons.notifications_outlined;
    final color = _typeColors[type] ?? AppColors.primary;

    return Material(
      color: isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.03),
      child: InkWell(
        onTap: () async {
          if (!isRead && notificationId != null) {
            final service = AppNotificationService();
            await service.markAsRead(notificationId);
            onRefresh?.call();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _formatTimeAgo(createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays ~/ 7}w ago';
    } catch (_) {
      return '';
    }
  }

  Widget _buildSkeleton() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.notifications_none, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'No notifications',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
