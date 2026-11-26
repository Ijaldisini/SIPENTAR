import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../models/auth/auth_response_model.dart';
import '../../models/auth/user_model.dart';

class AuthServiceException implements Exception {
  final String message;
  final int statusCode;

  const AuthServiceException({required this.message, required this.statusCode});

  @override
  String toString() => message;
}

class AuthService {
  final ApiClient _apiClient;

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Map<String, dynamic> _decodeResponse(String responseBody) {
    final dynamic decoded;

    try {
      decoded = jsonDecode(responseBody);
    } on FormatException {
      throw const FormatException('Response server bukan JSON yang valid.');
    }

    if (decoded is! Map) {
      throw const FormatException('Format response server tidak valid.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  String _getMessage(Map<String, dynamic> response, String fallback) {
    final message = response['message'];

    if (message is String && message.isNotEmpty) {
      return message;
    }

    return fallback;
  }

  Future<AuthResponseModel> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'username': username, 'password': password},
    );

    final json = _decodeResponse(response.body);

    final authResponse = AuthResponseModel.fromJson(json);

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

      await TokenStorage.saveToken(token);
    }

    return authResponse;
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await TokenStorage.getToken();

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    final response = await _apiClient.get('/me', token: token);

    if (response.statusCode == 401) {
      await TokenStorage.deleteToken();
      return null;
    }

    final json = _decodeResponse(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthServiceException(
        message: _getMessage(json, 'Gagal memeriksa sesi pengguna.'),
        statusCode: response.statusCode,
      );
    }

    final rawData = json['data'];

    if (rawData is! Map) {
      throw const FormatException('Data pengguna dari server tidak ditemukan.');
    }

    final userJson = Map<String, dynamic>.from(rawData);

    return UserModel.fromJson(userJson);
  }

  Future<void> logout() async {
    final token = await TokenStorage.getToken();

    if (token == null || token.trim().isEmpty) {
      await TokenStorage.deleteToken();
      return;
    }

    try {
      final response = await _apiClient.post('/auth/logout', token: token);

      if ((response.statusCode < 200 || response.statusCode >= 300) &&
          response.statusCode != 401) {
        final json = _decodeResponse(response.body);

        throw AuthServiceException(
          message: _getMessage(json, 'Logout gagal. Silakan coba lagi.'),
          statusCode: response.statusCode,
        );
      }
    } finally {
      await TokenStorage.deleteToken();
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}
