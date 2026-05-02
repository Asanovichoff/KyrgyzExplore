import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(dio: ref.read(dioProvider));
});

class NotificationRepository {
  NotificationRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<NotificationModel>> getNotifications(
      {int page = 0, int size = 20}) async {
    final res = await _dio.get(
      '/notifications/my',
      queryParameters: {'page': page, 'size': size},
    );
    final content = res.data['data']['content'] as List<dynamic>;
    return content
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final res = await _dio.get('/notifications/my/unread-count');
    return res.data['data'] as int;
  }

  Future<void> markRead(String id) async {
    await _dio.post('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.post('/notifications/read-all');
  }
}
