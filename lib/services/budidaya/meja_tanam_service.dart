import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../models/budidaya/budidaya_model.dart';

/// Membaca daftar meja tanam untuk pilihan meja pada form budidaya.
/// Endpoint backend yang digunakan hanya GET /meja-tanam.
class MejaTanamService {
  final ApiClient _apiClient;

  MejaTanamService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static const String _endpoint = '/meja-tanam';

  Future<List<BudidayaMejaModel>> getMejaTanams({int perPage = 100}) async {
    if (perPage < 1) {
      throw ArgumentError.value(
        perPage,
        'perPage',
        'Jumlah data per halaman harus lebih besar dari 0.',
      );
    }

    final token = await TokenStorage.getToken();
    if (token == null || token.trim().isEmpty) {
      throw const MejaTanamServiceException(
        message: 'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    final result = <BudidayaMejaModel>[];
    var page = 1;
    var lastPage = 1;

    do {
      final response = await _apiClient.get(
        _endpoint,
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
        token: token.trim(),
      );

      final Map<String, dynamic> responseJson;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          throw const FormatException('Format respons meja tanam tidak valid.');
        }
        responseJson = Map<String, dynamic>.from(decoded);
      } on FormatException {
        throw const FormatException('Respons server bukan JSON yang valid.');
      }

      final success = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          responseJson['success'] != false;
      if (!success) {
        throw MejaTanamServiceException(
          message: _readErrorMessage(responseJson),
          statusCode: response.statusCode,
        );
      }

      final rawPayload = responseJson['data'];
      if (rawPayload is! Map) {
        throw const FormatException('Data meja tanam tidak ditemukan.');
      }
      final payload = Map<String, dynamic>.from(rawPayload);
      final rawItems = payload['data'];
      if (rawItems is! List) {
        throw const FormatException('Daftar meja tanam tidak valid.');
      }

      for (final rawItem in rawItems) {
        if (rawItem is! Map) {
          throw const FormatException('Format item meja tanam tidak valid.');
        }
        result.add(
          BudidayaMejaModel.fromJson(Map<String, dynamic>.from(rawItem)),
        );
      }

      final rawMeta = payload['meta'];
      if (rawMeta is Map) {
        final meta = Map<String, dynamic>.from(rawMeta);
        lastPage = _readInt(meta['last_page'], fallback: page);
      } else {
        lastPage = page;
      }

      page++;
    } while (page <= lastPage);

    return result;
  }

  String _readErrorMessage(Map<String, dynamic> responseJson) {
    final errors = responseJson['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    final message = responseJson['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'Gagal mengambil daftar meja tanam.';
  }

  int _readInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  void dispose() => _apiClient.dispose();
}

class MejaTanamServiceException implements Exception {
  final String message;
  final int? statusCode;

  const MejaTanamServiceException({required this.message, this.statusCode});

  @override
  String toString() => message;
}
