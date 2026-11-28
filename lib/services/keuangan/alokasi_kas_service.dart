import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../models/keuangan/alokasi_kas_model.dart';

/// Service untuk membaca ringkasan alokasi kas pada tanggal tertentu.
///
/// Endpoint: GET /keuangan/alokasi-kas?tanggal=YYYY-MM-DD
/// Endpoint ini hanya membaca total pemasukan dan kas operasional.
/// Backend belum menyediakan endpoint untuk menyimpan atau mengubah alokasi.
class AlokasiKasService {
  final ApiClient _apiClient;

  AlokasiKasService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static const String _endpoint = '/keuangan/alokasi-kas';

  Future<String> _getToken() async {
    final token = await TokenStorage.getToken();

    if (token == null || token.trim().isEmpty) {
      throw const AlokasiKasServiceException(
        message: 'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    return token.trim();
  }

  String _validateDate(String tanggal) {
    final normalized = tanggal.trim();
    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

    if (!datePattern.hasMatch(normalized)) {
      throw ArgumentError.value(
        tanggal,
        'tanggal',
        'Tanggal harus menggunakan format YYYY-MM-DD.',
      );
    }

    final parsedDate = DateTime.tryParse(normalized);
    if (parsedDate == null ||
        parsedDate.toIso8601String().substring(0, 10) != normalized) {
      throw ArgumentError.value(
        tanggal,
        'tanggal',
        'Tanggal yang dimasukkan tidak valid.',
      );
    }

    return normalized;
  }

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

  String _messageFromResponse(
    Map<String, dynamic> responseJson, {
    String fallback = 'Permintaan data alokasi kas gagal.',
  }) {
    final errors = responseJson['errors'];

    if (errors is Map) {
      final validationMessages = <String>[];

      for (final value in errors.values) {
        if (value is List) {
          validationMessages.addAll(
            value
                .map((item) => item.toString())
                .where((message) => message.trim().isNotEmpty),
          );
        } else if (value is String && value.trim().isNotEmpty) {
          validationMessages.add(value.trim());
        }
      }

      if (validationMessages.isNotEmpty) {
        return validationMessages.join('\n');
      }
    }

    final message = responseJson['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    return fallback;
  }

  void _checkResponse(
    int statusCode,
    Map<String, dynamic> responseJson, {
    required String fallbackMessage,
  }) {
    final isHttpSuccess = statusCode >= 200 && statusCode < 300;
    final apiSuccess = responseJson['success'];

    if (!isHttpSuccess || apiSuccess == false) {
      throw AlokasiKasServiceException(
        message: _messageFromResponse(
          responseJson,
          fallback: fallbackMessage,
        ),
        statusCode: statusCode,
      );
    }

    if (apiSuccess != null && apiSuccess != true) {
      throw AlokasiKasServiceException(
        message: fallbackMessage,
        statusCode: statusCode,
      );
    }
  }

  Map<String, dynamic> _extractPayload(
    Map<String, dynamic> responseJson,
  ) {
    final rawData = responseJson['data'];

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    throw const FormatException(
      'Data alokasi kas dari server tidak ditemukan.',
    );
  }

  /// Mengambil total pemasukan dan total kas operasional pada [tanggal].
  ///
  /// [tanggal] wajib berformat YYYY-MM-DD. Hanya role `pemilik` yang
  /// diizinkan backend untuk mengakses endpoint ini.
  Future<AlokasiKasModel> getAlokasiKas({required String tanggal}) async {
    final validDate = _validateDate(tanggal);
    final token = await _getToken();

    final response = await _apiClient.get(
      _endpoint,
      queryParameters: {'tanggal': validDate},
      token: token,
    );

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal mengambil data alokasi kas.',
    );

    final payload = _extractPayload(responseJson);
    return AlokasiKasModel.fromJson(payload);
  }

  void dispose() {
    _apiClient.dispose();
  }
}

/// Error terstruktur dari service alokasi kas.
class AlokasiKasServiceException implements Exception {
  final String message;
  final int? statusCode;

  const AlokasiKasServiceException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}
