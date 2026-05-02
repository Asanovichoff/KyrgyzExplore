import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(dio: ref.read(dioProvider));
});

class ReviewRepository {
  ReviewRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<void> createReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    await _dio.post('/reviews', data: {
      'bookingId': bookingId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }
}
