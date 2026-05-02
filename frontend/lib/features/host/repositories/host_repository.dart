import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/listing_model.dart';
import '../models/listing_form_models.dart';
import '../models/payout_model.dart';

final hostRepositoryProvider = Provider<HostRepository>((ref) {
  return HostRepository(dio: ref.read(dioProvider));
});

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
      data: Uint8List.fromList(bytes),
      options: Options(
        headers: {'Content-Type': 'image/jpeg'},
      ),
    );
  }

  Future<void> confirmImage(String listingId, String s3Key) async {
    await _dio.post('/listings/$listingId/images', data: {'s3Key': s3Key});
  }

  Future<void> deleteImage(String listingId, String imageId) async {
    await _dio.delete('/listings/$listingId/images/$imageId');
  }

  // ── Payouts ────────────────────────────────────────────────────────────────

  Future<List<PayoutModel>> getPayouts({int page = 0, int size = 50}) async {
    final res = await _dio.get(
      '/payouts',
      queryParameters: {'page': page, 'size': size},
    );
    final content = res.data['data']['content'] as List<dynamic>;
    return content
        .map((e) => PayoutModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Stripe Connect ─────────────────────────────────────────────────────────

  Future<String> createConnectOnboarding() async {
    final res = await _dio.post('/users/stripe-connect');
    return res.data['data']['onboardingUrl'] as String;
  }

  Future<ConnectStatusModel> getConnectStatus() async {
    final res = await _dio.get('/users/stripe-connect/status');
    return ConnectStatusModel.fromJson(
        res.data['data'] as Map<String, dynamic>);
  }

  // ── Availability ───────────────────────────────────────────────────────────

  Future<List<String>> getAvailability(
      String listingId, int year, int month) async {
    final res = await _dio.get(
      '/listings/$listingId/availability',
      queryParameters: {'year': year, 'month': month},
    );
    return List<String>.from(
        res.data['data']['blockedDates'] as List<dynamic>);
  }

  Future<void> updateAvailability({
    required String listingId,
    required List<String> blockedDates,
    required List<String> unblockedDates,
  }) async {
    await _dio.put(
      '/listings/$listingId/availability',
      data: {
        'blockedDates': blockedDates,
        'unblockedDates': unblockedDates,
      },
    );
  }
}

class ConnectStatusModel {
  const ConnectStatusModel({
    required this.chargesEnabled,
    required this.detailsSubmitted,
    this.accountId,
  });

  factory ConnectStatusModel.fromJson(Map<String, dynamic> json) =>
      ConnectStatusModel(
        chargesEnabled: json['chargesEnabled'] as bool,
        detailsSubmitted: json['detailsSubmitted'] as bool,
        accountId: json['accountId'] as String?,
      );

  final bool chargesEnabled;
  final bool detailsSubmitted;
  final String? accountId;
}
