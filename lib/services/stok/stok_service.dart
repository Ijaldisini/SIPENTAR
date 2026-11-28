import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../models/stok/stok_model.dart';

class StokService {
  final ApiClient _apiClient;

  StokService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<String> _getToken() async {
    final token = await TokenStorage.getToken();

    if (token == null || token.trim().isEmpty) {
      throw const StokServiceException('Sesi login tidak ditemukan.');
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
      throw StokServiceException(_getErrorMessage(json), statusCode);
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

    return 'Terjadi kesalahan pada data stok.';
  }

  StokModel _parseStok(dynamic data) {
    if (data is! Map) {
      throw const FormatException('Format data stok tidak valid.');
    }

    return StokModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<StokPageResult> getStoksPage({int page = 1, int perPage = 15}) async {
    final token = await _getToken();

    final response = await _apiClient.get(
      '/stok',
      queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
      token: token,
    );

    final decoded = _decodeResponse(response.body);

    if (decoded is! Map) {
      throw const FormatException('Format response daftar stok tidak valid.');
    }

    final json = Map<String, dynamic>.from(decoded);

    _checkResponse(response.statusCode, json);

    final result = json['data'];

    if (result is! Map || result['data'] is! List) {
      throw const FormatException('Daftar stok tidak ditemukan.');
    }

    final rawStocks = result['data'] as List;
    final rawMeta = result['meta'];

    if (rawMeta is! Map) {
      throw const FormatException('Metadata pagination stok tidak ditemukan.');
    }

    int parseNumber(dynamic value, int fallback) {
      if (value is int) return value;

      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return StokPageResult(
      stocks: rawStocks.map(_parseStok).toList(),
      currentPage: parseNumber(rawMeta['current_page'], page),
      lastPage: parseNumber(rawMeta['last_page'], page),
      perPage: parseNumber(rawMeta['per_page'], perPage),
      total: parseNumber(rawMeta['total'], rawStocks.length),
    );
  }

  Future<List<StokModel>> getStoks({int page = 1, int perPage = 15}) async {
    final result = await getStoksPage(page: page, perPage: perPage);

    return result.stocks;
  }

  Future<StokModel> getStokById({required int id}) async {
    final token = await _getToken();

    final response = await _apiClient.get('/stok/$id', token: token);

    final decoded = _decodeResponse(response.body);

    if (decoded is! Map) {
      throw const FormatException('Format response detail stok tidak valid.');
    }

    final json = Map<String, dynamic>.from(decoded);

    _checkResponse(response.statusCode, json);

    return _parseStok(json['data']);
  }

  Future<StokModel> createStok({
    required String namaBahan,
    required String kategori,
    required String satuan,
    required double jumlahStok,
    required double batasMinimum,
  }) async {
    final token = await _getToken();

    final response = await _apiClient.post(
      '/stok',
      body: {
        'nama_bahan': namaBahan.trim(),
        'kategori': kategori.trim(),
        'satuan': satuan.trim(),
        'jumlah_stok': jumlahStok,
        'batas_minimum': batasMinimum,
      },
      token: token,
    );

    final decoded = _decodeResponse(response.body);

    if (decoded is! Map) {
      throw const FormatException('Format response tambah stok tidak valid.');
    }

    final json = Map<String, dynamic>.from(decoded);

    _checkResponse(response.statusCode, json);

    return _parseStok(json['data']);
  }

  Future<StokModel> updateStok({
    required int id,
    required String namaBahan,
    required String kategori,
    required String satuan,
    required double jumlahStok,
    required double batasMinimum,
  }) async {
    final token = await _getToken();

    final response = await _apiClient.put(
      '/stok/$id',
      body: {
        'nama_bahan': namaBahan.trim(),
        'kategori': kategori.trim(),
        'satuan': satuan.trim(),
        'jumlah_stok': jumlahStok,
        'batas_minimum': batasMinimum,
      },
      token: token,
    );

    final decoded = _decodeResponse(response.body);

    if (decoded is! Map) {
      throw const FormatException('Format response edit stok tidak valid.');
    }

    final json = Map<String, dynamic>.from(decoded);

    _checkResponse(response.statusCode, json);

    return _parseStok(json['data']);
  }

  Future<void> deleteStok({required int id}) async {
    final token = await _getToken();

    final response = await _apiClient.delete('/stok/$id', token: token);

    final decoded = _decodeResponse(response.body);

    if (decoded is! Map) {
      throw const FormatException('Format response hapus stok tidak valid.');
    }

    final json = Map<String, dynamic>.from(decoded);

    _checkResponse(response.statusCode, json);
  }

  void dispose() {
    _apiClient.dispose();
  }
}

class StokServiceException implements Exception {
  final String message;
  final int? statusCode;

  const StokServiceException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class StokPageResult {
  final List<StokModel> stocks;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const StokPageResult({
    required this.stocks,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}
