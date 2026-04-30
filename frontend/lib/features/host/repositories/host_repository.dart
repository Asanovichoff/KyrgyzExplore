import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../explore/models/listing_model.dart';

final hostRepositoryProvider = Provider<HostRepository>((ref) {
  return HostRepository(dio: ref.read(dioProvider));
});

class PresignModel {
  const PresignModel({required this.uploadUrl, required this.s3Key});
  final String uploadUrl;
  final String s3Key;
}

class CreateListingData {
  const CreateListingData({
    required this.type,
    required this.title,
    required this.description,
    required this.pricePerUnit,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    this.currency = 'KGS',
    this.maxGuests,
  });

  final String type;
  final String title;
  final String description;
  final double pricePerUnit;
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String currency;
  final int? maxGuests;

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'description': description,
        'pricePerUnit': pricePerUnit,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'city': city,
        'currency': currency,
        if (maxGuests != null) 'maxGuests': maxGuests,
      };
}

class HostRepository {
  HostRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // Bare Dio with no interceptors — presigned S3 URLs embed AWS auth credentials
  // in the URL itself. Adding a Bearer token header would break the AWS signature.
  static final _s3Dio = Dio();

  Future<List<ListingModel>> myListings({int page = 0, int size = 20}) async {
    final res = await _dio.get(
      '/listings/host/my',
      queryParameters: {'page': page, 'size': size},
    );
    final content = res.data['data']['content'] as List<dynamic>;
    return content
        .map((e) => ListingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ListingModel> create(CreateListingData data) async {
    final res = await _dio.post('/listings', data: data.toJson());
    return ListingModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ListingModel> update(String id, CreateListingData data) async {
    final res = await _dio.put('/listings/$id', data: data.toJson());
    return ListingModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/listings/$id');
  }

  Future<PresignModel> presignImage(String listingId) async {
    final res = await _dio.post('/listings/images/presign',
        data: {'listingId': listingId});
    final data = res.data['data'] as Map<String, dynamic>;
    return PresignModel(
      uploadUrl: data['uploadUrl'] as String,
      s3Key: data['s3Key'] as String,
    );
  }

  Future<void> uploadToS3(String uploadUrl, List<int> bytes) async {
    await _s3Dio.put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': 'image/jpeg',
          'Content-Length': bytes.length,
        },
      ),
    );
  }

  Future<void> confirmImage(String listingId, String s3Key) async {
    await _dio.post('/listings/$listingId/images', data: {'s3Key': s3Key});
  }

  Future<void> deleteImage(String listingId, String imageId) async {
    await _dio.delete('/listings/$listingId/images/$imageId');
  }
}
