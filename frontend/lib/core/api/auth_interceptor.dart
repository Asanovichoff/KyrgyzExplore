import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kAccessToken  = 'access_token';
const _kRefreshToken = 'refresh_token';

/// Attaches the Bearer token to every outgoing request.
/// On 401, tries to refresh once; on second 401, clears storage (user logged out).
///
/// WHY handle refresh here and not in the repository?
/// The interceptor runs for every request automatically. Putting refresh logic
/// in each repository method would mean duplicating it everywhere — and forgetting
/// it in one place means a silent logout. Centralising it here is the correct pattern.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._dio);

  final FlutterSecureStorage _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: _kAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 || _isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _storage.read(key: _kRefreshToken);
      if (refreshToken == null) {
        await _clearTokens();
        handler.next(err);
        return;
      }

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'skipAuthInterceptor': true}),
      );

      final newAccess  = response.data['accessToken']  as String;
      final newRefresh = response.data['refreshToken'] as String;
      await _storage.write(key: _kAccessToken,  value: newAccess);
      await _storage.write(key: _kRefreshToken, value: newRefresh);

      // Retry the original request with the new token
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      await _clearTokens();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }
}
