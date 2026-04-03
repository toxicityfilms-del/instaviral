import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kToken = 'reelboost_jwt';
const _kEmail = 'reelboost_email';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _kToken);
  Future<void> writeToken(String? v) async {
    if (v == null || v.isEmpty) {
      await _storage.delete(key: _kToken);
    } else {
      await _storage.write(key: _kToken, value: v);
    }
  }

  Future<String?> readEmail() => _storage.read(key: _kEmail);
  Future<void> writeEmail(String? v) async {
    if (v == null || v.isEmpty) {
      await _storage.delete(key: _kEmail);
    } else {
      await _storage.write(key: _kEmail, value: v);
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kEmail);
  }
}
