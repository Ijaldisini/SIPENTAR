import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';

  // Simpan token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Ambil token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Hapus token saat logout
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
