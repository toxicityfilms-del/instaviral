import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/features/creator_profile/data/creator_profile_repository.dart';
import 'package:reelboost_ai/models/user_model.dart';
import 'package:reelboost_ai/services/api_client.dart';
import 'package:reelboost_ai/services/auth_repository.dart';
import 'package:reelboost_ai/services/reelboost_api_service.dart';
import 'package:reelboost_ai/services/secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(dio, storage);
});

/// Dio with Bearer token and 401 → session clear + [authControllerProvider] reset.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(
    getToken: () => storage.readToken(),
    onUnauthorized: () async {
      await storage.clearSession();
      ref.invalidate(authControllerProvider);
    },
  ).dio;
});

final reelboostApiProvider = Provider<ReelboostApiService>((ref) {
  return ReelboostApiService(ref.watch(dioProvider));
});

final creatorProfileRepositoryProvider = Provider<CreatorProfileRepository>((ref) {
  return CreatorProfileRepositoryImpl(ref.watch(reelboostApiProvider));
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserModel?>(() => AuthController());

class AuthController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final session = await ref.read(authRepositoryProvider).restoreSession();
    if (session == null) return null;
    try {
      return await ref.read(reelboostApiProvider).getProfileMe();
    } catch (_) {
      return session;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final user = await ref.read(authRepositoryProvider).login(email: email, password: password);
      state = AsyncData(user);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signup(String email, String password, {String name = ''}) async {
    try {
      final user =
          await ref.read(authRepositoryProvider).signup(email: email, password: password, name: name);
      state = AsyncData(user);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  /// After profile PATCH; keeps session, updates cached user fields.
  void applyUser(UserModel user) {
    state = AsyncData(user);
  }
}
