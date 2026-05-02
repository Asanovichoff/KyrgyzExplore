import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';
import '../../notification/repositories/device_repository.dart';

// The single source of truth for authentication state.
// null  = not logged in
// UserModel = logged in as this user
//
// WHY AsyncNotifierProvider and not a plain StateProvider?
// The initial state has to be loaded asynchronously from secure storage
// (getMe() makes a network call). AsyncNotifierProvider handles the
// loading/error/data lifecycle automatically — no need to manage it manually.
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    try {
      return await ref.read(authRepositoryProvider).getMe();
    } catch (_) {
      return null;
    }
  }

  Future<void> login(LoginRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(req),
    );
    if (state.hasValue && state.value != null) _registerFcmToken();
  }

  Future<void> register(RegisterRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(req),
    );
    if (state.hasValue && state.value != null) _registerFcmToken();
  }

  Future<void> logout() async {
    await _unregisterFcmToken();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  void updateUser(UserModel updated) {
    state = AsyncData(updated);
  }

  // Requests notification permission then registers the FCM token with the
  // backend so this device can receive push notifications.
  // Wrapped in try/catch — Firebase may not be configured in dev, and we
  // should never block login just because push setup fails.
  Future<void> _registerFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null) return;
      final platform =
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      await ref
          .read(deviceRepositoryProvider)
          .registerToken(token, platform);
    } catch (_) {}
  }

  Future<void> _unregisterFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await ref.read(deviceRepositoryProvider).unregisterToken(token);
    } catch (_) {}
  }
}
