import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../listing/models/review_model.dart';
import '../../../shared/models/listing_model.dart';
import '../models/search_params.dart';

final exploreRepositoryProvider = Provider<ExploreRepository>((ref) {
  return ExploreRepository(dio: ref.read(dioProvider));
});

class ExploreRepository {
  ExploreRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<ListingModel>> search(SearchParams params) async {
    final queryParams = <String, dynamic>{
      'lat': params.lat,
      'lon': params.lon,
      'radiusKm': params.radiusKm,
      'sort': params.sort,
      'page': params.page,
      'size': 20,
      if (params.type != null) 'type': params.type,
      if (params.minPrice != null) 'minPrice': params.minPrice,
      if (params.maxPrice != null) 'maxPrice': params.maxPrice,
      if (params.minGuests != null) 'minGuests': params.minGuests,
      if (params.city != null && params.city!.isNotEmpty) 'city': params.city,
      if (params.checkIn != null) 'checkIn': _fmtDate(params.checkIn!),
      if (params.checkOut != null) 'checkOut': _fmtDate(params.checkOut!),
    };

    final response = await _dio.get(
      '/listings/search',
      queryParameters: queryParams,
    );

    // Response shape: { "success": true, "data": { "content": [...], ... } }
    final page = response.data['data'] as Map<String, dynamic>;
    final content = page['content'] as List<dynamic>;
    return content
        .map((e) => ListingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ListingModel> getById(String id) async {
    final res = await _dio.get('/listings/$id');
    return ListingModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<String>> getAvailability(String id, int year, int month) async {
    final res = await _dio.get(
      '/listings/$id/availability',
      queryParameters: {'year': year, 'month': month},
    );
    return List<String>.from(
        (res.data['data']['blockedDates'] as List<dynamic>));
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<ReviewModel>> getReviews(String id) async {
    final res = await _dio.get(
      '/reviews/listing/$id',
      queryParameters: {'page': 0, 'size': 5},
    );
    final content = res.data['data']['content'] as List<dynamic>;
    return content
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
