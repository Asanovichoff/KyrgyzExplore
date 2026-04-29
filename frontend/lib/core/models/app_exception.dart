// Sealed class — the compiler enforces exhaustive handling in every switch.
// WHY sealed and not a plain abstract class? With a sealed class, if you add a
// new variant (e.g. RateLimitException), the compiler flags every switch that
// doesn't handle it. You can never silently ignore a new error type.
sealed class AppException implements Exception {
  const AppException();
}

/// No internet or the server didn't respond.
class NetworkException extends AppException {
  const NetworkException(this.message);
  final String message;
}

/// 401 Unauthorized — token missing or expired and refresh failed.
/// The router listens for this and redirects to /auth/login.
class AuthException extends AppException {
  const AuthException();
}

/// 4xx / 5xx from the API with a structured error body.
class ServerException extends AppException {
  const ServerException({required this.statusCode, required this.code, required this.message});
  final int statusCode;
  final String code;
  final String message;
}

/// 422 / validation errors — field-level messages from the API.
class ValidationException extends AppException {
  const ValidationException(this.errors);
  final Map<String, String> errors;
}
