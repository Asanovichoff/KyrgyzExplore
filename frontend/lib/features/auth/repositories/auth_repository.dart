import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../models/auth_models.dart';

const _kAccessToken  = 'access_token';
const _kRefreshToken = 'refresh_token';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.read(dioProvider),
    storage: ref.read(secureStorageProvider),
  );
});

class AuthRepository {
  AuthRepository({required Dio dio, required FlutterSecureStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<UserModel> login(LoginRequest req) async {
    final response = await _dio.post('/auth/login', data: req.toJson());
    // Backend wraps all responses: { "success": true, "data": { ... } }
    // We must unwrap ['data'] to reach the actual AuthResponse payload.
    final data = response.data['data'] as Map<String, dynamic>;
    await _saveTokens(TokenPair.fromJson(data));
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> register(RegisterRequest req) async {
    final response = await _dio.post('/auth/register', data: req.toJson());
    final data = response.data['data'] as Map<String, dynamic>;
    await _saveTokens(TokenPair.fromJson(data));
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } finally {
      // Always clear local tokens even if the server call fails.
      // If we don't, the user would be stuck in a logged-in state with an
      // invalid token and no way to get back to the login screen.
      await _clearTokens();
    }
  }

  /// Called on app startup to restore the session from stored tokens.
  /// Returns null if no token is stored (user never logged in or was logged out).
  Future<UserModel?> getMe() async {
    final token = await _storage.read(key: _kAccessToken);
    if (token == null) return null;
    final response = await _dio.get('/users/me');
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Exposes the stored JWT so the WebSocket client can attach it to the
  /// STOMP CONNECT frame. The token is short-lived; callers should fetch it
  /// fresh before opening each WebSocket connection.
  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);

  Future<void> _saveTokens(TokenPair pair) async {
    await _storage.write(key: _kAccessToken,  value: pair.accessToken);
    await _storage.write(key: _kRefreshToken, value: pair.refreshToken);
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }
}
