import 'package:dio/dio.dart';
import 'package:reelboost_ai/core/utils/dio_error_message.dart';
import 'package:reelboost_ai/models/user_model.dart';
import 'package:reelboost_ai/services/secure_storage_service.dart';

/// Auth API calls use the shared [Dio] from [dioProvider] (`ApiClient`):
/// base URL from [ApiService.baseUrl], `Authorization: Bearer` on authenticated routes.
class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;

  Future<UserModel> signup({
    required String email,
    required String password,
    String name = '',
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {'email': email, 'password': password, if (name.isNotEmpty) 'name': name},
    );
    return _persistAuthResponse(res.data!);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _persistAuthResponse(res.data!);
  }

  Future<String> forgotPassword({required String email}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email},
      );
      final data = res.data ?? const <String, dynamic>{};
      final ok = data['success'] == true;
      if (!ok) {
        throw AuthException(data['message']?.toString() ?? 'Failed to request password reset');
      }
      return data['message']?.toString() ??
          'If this email is registered, a password reset link has been sent.';
    } on DioException catch (e) {
      throw AuthException(_dioErrorMessage(e) ?? 'Failed to request password reset');
    }
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {'token': token, 'password': newPassword},
      );
      final data = res.data ?? const <String, dynamic>{};
      final ok = data['success'] == true;
      if (!ok) {
        throw AuthException(data['message']?.toString() ?? 'Failed to reset password');
      }
      return data['message']?.toString() ?? 'Password reset successful';
    } on DioException catch (e) {
      throw AuthException(_dioErrorMessage(e) ?? 'Failed to reset password');
    }
  }

  Future<UserModel> _persistAuthResponse(Map<String, dynamic> data) async {
    if (data['success'] != true) {
      throw AuthException(data['message']?.toString() ?? 'Auth failed');
    }
    final token = data['token'] as String?;
    final userJson = data['user'] as Map<String, dynamic>?;
    if (token == null || userJson == null) {
      throw const AuthException('Invalid auth response');
    }
    final user = UserModel.fromJson(userJson);
    await _storage.writeToken(token.trim());
    await _storage.writeEmail(user.email);
    return user;
  }

  Future<UserModel?> restoreSession() async {
    final token = await _storage.readToken();
    final email = await _storage.readEmail();
    if (token == null || token.isEmpty || email == null) return null;
    return UserModel(id: '', email: email, name: '');
  }

  Future<String?> getToken() => _storage.readToken();

  Future<void> logout() => _storage.clearSession();

  String? _dioErrorMessage(DioException e) {
    final fromDio = dioErrorMessage(e);
    if (fromDio != null && fromDio.trim().isNotEmpty) return fromDio.trim();
    return e.message;
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
