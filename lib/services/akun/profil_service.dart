import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../models/auth/user_model.dart';

class ProfilService {
  final ApiClient _apiClient;

  ProfilService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<UserModel> updateProfile({
    required String nama,
    required String username,
    String? password,
  }) async {
    final token = await TokenStorage.getToken();

    if (token == null || token.trim().isEmpty) {
      throw ProfilServiceException('Sesi login tidak ditemukan.');
    }

    final body = <String, dynamic>{
      'nama': nama.trim(),
      'username': username.trim(),
    };

    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    final response = await _apiClient.put('/profil', body: body, token: token);

    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('Response server bukan JSON yang valid.');
    }

    if (decoded is! Map) {
      throw const FormatException('Format response profil tidak valid.');
    }

    final json = Map<String, dynamic>.from(decoded);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        json['success'] != true) {
      throw ProfilServiceException(_getErrorMessage(json), response.statusCode);
    }

    final data = json['data'];

    if (data is! Map) {
      throw const FormatException(
        'Data profil tidak ditemukan pada response server.',
      );
    }

    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  String _getErrorMessage(Map<String, dynamic> json) {
    final errors = json['errors'];

    if (errors is Map) {
      for (final error in errors.values) {
        if (error is List && error.isNotEmpty) {
          return error.first.toString();
        }

        if (error is String && error.isNotEmpty) {
          return error;
        }
      }
    }

    final message = json['message'];

    if (message is String && message.isNotEmpty) {
      return message;
    }

    return 'Gagal memperbarui profil.';
  }

  void dispose() {
    _apiClient.dispose();
  }
}

class ProfilServiceException implements Exception {
  final String message;
  final int? statusCode;

  const ProfilServiceException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}
