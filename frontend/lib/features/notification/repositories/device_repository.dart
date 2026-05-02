import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(dio: ref.read(dioProvider));
});

class DeviceRepository {
  DeviceRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<void> registerToken(String token, String platform) async {
    await _dio.post('/devices/token', data: {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unregisterToken(String token) async {
    await _dio.delete('/devices/token', data: {'token': token});
  }
}
