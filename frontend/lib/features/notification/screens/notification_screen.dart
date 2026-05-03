import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/l10n/l10n_extension.dart';
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
        title: Text(context.l10n.notifications),
        actions: [
          TextButton(
            onPressed: () async {
              await ref
                  .read(notificationRepositoryProvider)
                  .markAllRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: Text(context.l10n.markAllRead),
          ),
        ],
      ),
      body: asyncNotifs.when(
        loading: () => const _NotificationsListSkeleton(),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: kGrey),
              const SizedBox(height: 12),
              Text(context.l10n.couldNotLoadNotifications),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none_outlined,
                      size: 64, color: kGrey),
                  const SizedBox(height: 16),
                  Text(context.l10n.noNotificationsYet,
                      style: const TextStyle(color: kGrey, fontSize: 16)),
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

class _NotificationsListSkeleton extends StatelessWidget {
  const _NotificationsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        itemCount: 6,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 18),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 13, width: 180, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 11, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(height: 11, width: 240, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 60, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                    _timeAgo(context, notification.createdAt),
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

  String _timeAgo(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return context.l10n.timeJustNow;
    if (diff.inMinutes < 60) return context.l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return context.l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return context.l10n.timeDaysAgo(diff.inDays);
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
