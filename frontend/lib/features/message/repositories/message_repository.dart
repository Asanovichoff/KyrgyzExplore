import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/message_model.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(dio: ref.read(dioProvider));
});

class MessageRepository {
  MessageRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<MessageModel>> getHistory(String bookingId) async {
    final res = await _dio.get(
      '/messages/$bookingId',
      queryParameters: {'page': 0, 'size': 50, 'sort': 'createdAt,asc'},
    );
    final content = res.data['data']['content'] as List<dynamic>;
    return content
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String bookingId) async {
    await _dio.post('/messages/$bookingId/read');
  }
}
