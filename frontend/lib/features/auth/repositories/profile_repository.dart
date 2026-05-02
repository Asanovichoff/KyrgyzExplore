import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
    String? profileImageUrl,
  }) async {
    final res = await _dio.put('/users/me', data: {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    });
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Picks a photo from the gallery, uploads it to S3 via a presigned URL,
  /// then persists the permanent image URL on the user profile.
  /// Returns the updated UserModel, or null if the user cancelled the picker.
  ///
  /// WHY two-step (presign then PUT /users/me)?
  /// The image goes directly from the phone to S3 — the app server never touches
  /// the bytes, saving bandwidth and memory. Only the final URL hits our API.
  Future<UserModel?> uploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return null;

    // Step 1: get a short-lived presigned PUT URL from our backend.
    final presignRes = await _dio.post('/users/me/avatar/presign');
    final uploadUrl = presignRes.data['data']['uploadUrl'] as String;
    final imageUrl  = presignRes.data['data']['imageUrl']  as String;

    // Step 2: upload the image bytes directly to S3 (no auth header needed).
    final Uint8List bytes = await picked.readAsBytes();
    final s3Dio = Dio();
    await s3Dio.put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': 'image/jpeg',
          'Content-Length': bytes.length,
        },
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    // Step 3: persist the permanent URL on the user record.
    return updateMe(profileImageUrl: imageUrl);
  }
}
