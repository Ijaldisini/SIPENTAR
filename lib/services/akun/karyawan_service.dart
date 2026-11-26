import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../models/auth/user_model.dart';

class KaryawanService {
  final ApiClient _apiClient;

  KaryawanService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<String> _getToken() async {
    final token = await TokenStorage.getToken();

    if (token == null || token.trim().isEmpty) {
      throw const KaryawanServiceException('Sesi login tidak ditemukan.');
    }

    return token;
  }

  dynamic _decodeResponse(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const FormatException('Response server bukan JSON yang valid.');
    }
  }

  void _checkResponse(int statusCode, Map<String, dynamic> json) {
    if (statusCode < 200 || statusCode >= 300 || json['success'] != true) {
      throw KaryawanServiceException(_getErrorMessage(json), statusCode);
    }
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

    return 'Terjadi kesalahan pada data karyawan.';
  }

  UserModel _parseUser(dynamic data) {
    if (data is! Map) {
      throw const FormatException('Format data karyawan tidak valid.');
    }

    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<KaryawanPageResult> getEmployeesPage({
    int page = 1,
    int perPage = 15,
  }) async {
    final token = await _getToken();

    final response = await _apiClient.get(
      '/karyawan',
      queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
      token: token,
    );

    final decoded = _decodeResponse(response.body);

    if (decoded is! Map) {
      throw const FormatException(
        'Format response daftar karyawan tidak valid.',
      );
    }

    final json = Map<String, dynamic>.from(decoded);

    _checkResponse(response.statusCode, json);

    final result = json['data'];

    if (result is! Map || result['data'] is! List) {
      throw const FormatException('Daftar karyawan tidak ditemukan.');
    }

    final rawEmployees = result['data'] as List;
    final rawMeta = result['meta'];

    if (rawMeta is! Map) {
      throw const FormatException('Metadata pagination tidak ditemukan.');
    }

    int parseNumber(dynamic value, int fallback) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return KaryawanPageResult(
      employees: rawEmployees.map(_parseUser).toList(),
      currentPage: parseNumber(rawMeta['current_page'], page),
      lastPage: parseNumber(rawMeta['last_page'], page),
      total: parseNumber(rawMeta['total'], rawEmployees.length),
    );
  }

  Future<List<UserModel>> getEmployees({int page = 1, int perPage = 15}) async {
    final result = await getEmployeesPage(page: page, perPage: perPage);

    return result.employees;
  }

  Future<UserModel> createEmployee({
    required String nama,
    required String username,
    required String password,
  }) async {
    final token = await _getToken();

    final response = await _apiClient.post(
      '/karyawan',
      body: {
        'nama': nama.trim(),
        'username': username.trim(),
        'password': password,
      },
      token: token,
    );

    final decoded = _decodeResponse(response.body);

    if (decoded is! Map) {
      throw const FormatException(
        'Format response tambah karyawan tidak valid.',
      );
    }

    final json = Map<String, dynamic>.from(decoded);

    _checkResponse(response.statusCode, json);

    return _parseUser(json['data']);
  }

  Future<UserModel> getEmployeeById({required int id}) async {
    final token = await _getToken();

    final response = await _apiClient.get('/karyawan/$id', token: token);

    final decoded = _decodeResponse(response.body);

    if (decoded is! Map) {
      throw const FormatException(
        'Format response detail karyawan tidak valid.',
      );
    }

    final json = Map<String, dynamic>.from(decoded);

    _checkResponse(response.statusCode, json);

    return _parseUser(json['data']);
  }

  Future<UserModel> updateEmployee({
    required int id,
    required String nama,
    required String username,
    String? password,
  }) async {
    final token = await _getToken();

    final body = <String, dynamic>{
      'nama': nama.trim(),
      'username': username.trim(),
    };

    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    final response = await _apiClient.put(
      '/karyawan/$id',
      body: body,
      token: token,
    );

    final decoded = _decodeResponse(response.body);

    if (decoded is! Map) {
      throw const FormatException('Format response edit karyawan tidak valid.');
    }

    final json = Map<String, dynamic>.from(decoded);

    _checkResponse(response.statusCode, json);

    return _parseUser(json['data']);
  }

  void dispose() {
    _apiClient.dispose();
  }
}

class KaryawanServiceException implements Exception {
  final String message;
  final int? statusCode;

  const KaryawanServiceException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class KaryawanPageResult {
  final List<UserModel> employees;
  final int currentPage;
  final int lastPage;
  final int total;

  const KaryawanPageResult({
    required this.employees,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}
