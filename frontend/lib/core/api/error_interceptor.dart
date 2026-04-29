import 'package:dio/dio.dart';
import '../models/app_exception.dart';

/// Converts every non-2xx Dio response into a typed AppException.
/// Placed last in the interceptor chain so auth_interceptor runs first.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appEx = _map(err);
    handler.next(err.copyWith(error: appEx));
  }

  AppException _map(DioException err) {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return NetworkException(err.message ?? 'No connection');
    }

    final response = err.response;
    if (response == null) return NetworkException(err.message ?? 'Unknown error');

    if (response.statusCode == 401) return const AuthException();

    // Our backend returns { "code": "...", "message": "..." }
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final code    = body['code']    as String? ?? 'UNKNOWN';
      final message = body['message'] as String? ?? 'An error occurred';
      return ServerException(
        statusCode: response.statusCode ?? 0,
        code: code,
        message: message,
      );
    }

    return ServerException(
      statusCode: response.statusCode ?? 0,
      code: 'UNKNOWN',
      message: 'An error occurred',
    );
  }
}
