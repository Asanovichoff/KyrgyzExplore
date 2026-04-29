import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';

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
  }

  Future<void> register(RegisterRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(req),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
