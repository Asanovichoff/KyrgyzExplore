import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../repositories/notification_repository.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifs = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref
                  .read(notificationRepositoryProvider)
                  .markAllRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: asyncNotifs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: kGrey),
              const SizedBox(height: 12),
              const Text('Could not load notifications'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 64, color: kGrey),
                  SizedBox(height: 16),
                  Text('No notifications yet',
                      style: TextStyle(color: kGrey, fontSize: 16)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _NotificationTile(
                notification: notifications[i],
                onTap: () async {
                  if (!notifications[i].isRead) {
                    await ref
                        .read(notificationRepositoryProvider)
                        .markRead(notifications[i].id);
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadCountProvider);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead
            ? null
            : kTeal.withValues(alpha: 0.05),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread dot
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 10),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: notification.isRead
                      ? Colors.transparent
                      : kTeal,
                ),
              ),
            ),

            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor(notification.type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _iconData(notification.type),
                size: 20,
                color: _iconColor(notification.type),
              ),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: kGrey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: kGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconData(String type) => switch (type) {
        'BOOKING_CONFIRMED' => Icons.check_circle_outline,
        'BOOKING_REJECTED' => Icons.cancel_outlined,
        'BOOKING_CANCELLED' => Icons.event_busy_outlined,
        'BOOKING_PAID' => Icons.payments_outlined,
        'NEW_BOOKING_REQUEST' => Icons.inbox_outlined,
        'NEW_MESSAGE' => Icons.chat_bubble_outline,
        'REVIEW_RECEIVED' => Icons.star_outline,
        _ => Icons.notifications_outlined,
      };

  Color _iconColor(String type) => switch (type) {
        'BOOKING_CONFIRMED' => Colors.green,
        'BOOKING_REJECTED' => Colors.red,
        'BOOKING_CANCELLED' => kGrey,
        'BOOKING_PAID' => kTeal,
        'NEW_BOOKING_REQUEST' => kNavy,
        'NEW_MESSAGE' => kTeal,
        'REVIEW_RECEIVED' => Colors.amber,
        _ => kGrey,
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
