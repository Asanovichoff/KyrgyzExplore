import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/listing_model.dart';
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
}
