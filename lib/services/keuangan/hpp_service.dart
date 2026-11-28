import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../models/keuangan/hpp_model.dart';

/// Service untuk mengakses kalkulasi HPP pada backend SIPENTAR.
///
/// Endpoint: GET /keuangan/hpp
/// Akses endpoint ini dibatasi untuk role `pemilik` oleh backend.
class HppService {
  final ApiClient _apiClient;

  HppService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static const String _endpoint = '/keuangan/hpp';

  Future<String> _getToken() async {
    final token = await TokenStorage.getToken();

    if (token == null || token.trim().isEmpty) {
      throw const HppServiceException(
        message: 'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    return token.trim();
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
    String fallback = 'Permintaan kalkulasi HPP gagal.',
  }) {
    final errors = responseJson['errors'];

    if (errors is Map) {
      final validationMessages = <String>[];

      for (final value in errors.values) {
        if (value is List) {
          validationMessages.addAll(
            value.map((item) => item.toString()).where(
              (message) => message.trim().isNotEmpty,
            ),
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
      throw HppServiceException(
        message: _messageFromResponse(
          responseJson,
          fallback: fallbackMessage,
        ),
        statusCode: statusCode,
      );
    }

    if (apiSuccess != null && apiSuccess != true) {
      throw HppServiceException(
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

    throw const FormatException('Data kalkulasi HPP dari server tidak ditemukan.');
  }

  /// Menghitung HPP melalui backend.
  ///
  /// - [lubang]: jumlah lubang tanam yang ingin dihitung.
  /// - [panenId]: ID panen; backend akan mengambil jumlah lubang dari data
  ///   budidaya yang terhubung dengan panen tersebut.
  ///
  /// Jika kedua parameter tidak diisi, backend menggunakan total kapasitas
  /// lubang dari seluruh meja tanam. Jika keduanya diisi, backend memprioritaskan
  /// [panenId].
  Future<HppModel> calculateHpp({
    int? lubang,
    int? panenId,
  }) async {
    if (lubang != null && lubang < 1) {
      throw ArgumentError.value(
        lubang,
        'lubang',
        'Jumlah lubang harus lebih besar dari 0.',
      );
    }

    if (panenId != null && panenId < 1) {
      throw ArgumentError.value(
        panenId,
        'panenId',
        'ID panen harus lebih besar dari 0.',
      );
    }

    final token = await _getToken();
    final queryParameters = <String, String>{};

    if (lubang != null) {
      queryParameters['lubang'] = lubang.toString();
    }

    if (panenId != null) {
      queryParameters['panen_id'] = panenId.toString();
    }

    final response = await _apiClient.get(
      _endpoint,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      token: token,
    );

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal menghitung HPP.',
    );

    final payload = _extractPayload(responseJson);
    return HppModel.fromJson(payload);
  }

  void dispose() {
    _apiClient.dispose();
  }
}

/// Error terstruktur dari service kalkulasi HPP.
class HppServiceException implements Exception {
  final String message;
  final int? statusCode;

  const HppServiceException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}
