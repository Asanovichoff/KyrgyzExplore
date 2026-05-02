import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) {
  return ref.read(notificationRepositoryProvider).getNotifications();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.read(notificationRepositoryProvider).getUnreadCount();
});
