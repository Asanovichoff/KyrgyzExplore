import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

// Single FlutterSecureStorage instance shared across the app.
// MacOsOptions: useDataProtectionKeychain=false uses the legacy Keychain
// Services API, which works in unsigned debug builds on macOS. The default
// (Data Protection Keychain) requires a signed provisioning profile.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    mOptions: MacOsOptions(useDataProtectionKeyChain: false),
  ),
);

// Single Dio instance with all interceptors wired up.
// WHY a Provider and not a plain global? Riverpod lets tests override this
// with a mock Dio — no global state to reset between tests.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(storage, dio),
    PrettyDioLogger(requestBody: true, responseBody: true),
    ErrorInterceptor(),
  ]);

  return dio;
});
