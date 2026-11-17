import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../models/auth/auth_response_model.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // Login menggunakan username dan password
  Future<AuthResponseModel> login({
    required String username,
    required String password,
  }) async {
    // Mengirim request ke Laravel
    final response = await _apiClient.post(
      '/auth/login',
      body: {'username': username, 'password': password},
    );

    // Mengubah response JSON menjadi Map
    final dynamic decodedResponse;

    try {
      decodedResponse = jsonDecode(response.body);
    } on FormatException {
      final bodyPreview = response.body.trim();

      final preview = bodyPreview.length > 250
          ? bodyPreview.substring(0, 250)
          : bodyPreview;

      throw FormatException(
        'Response server bukan JSON.\n'
        'HTTP Status: ${response.statusCode}\n'
        'Content-Type: ${response.headers['content-type']}\n'
        'Response: $preview',
      );
    }

    if (decodedResponse is! Map) {
      throw const FormatException('Format response dari server tidak valid.');
    }

    // Mengubah JSON menjadi AuthResponseModel
    final authResponse = AuthResponseModel.fromJson(
      Map<String, dynamic>.from(decodedResponse),
    );

    // Jika login berhasil
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        authResponse.success) {
      final token = authResponse.token;

      if (token == null || token.trim().isEmpty) {
        throw const FormatException('Token autentikasi tidak ditemukan.');
      }

      if (authResponse.user == null) {
        throw const FormatException('Data pengguna tidak ditemukan.');
      }

      // Simpan token secara aman
      await TokenStorage.saveToken(token);
    }

    return authResponse;
  }

  // Menutup HTTP Client
  void dispose() {
    _apiClient.dispose();
  }
}
