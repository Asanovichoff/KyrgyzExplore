import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/auth_models.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(dio: ref.read(dioProvider));
});

class ProfileRepository {
  ProfileRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<UserModel> getMe() async {
    final res = await _dio.get('/users/me');
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<UserModel> updateMe({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final res = await _dio.put('/users/me', data: {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
    });
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
