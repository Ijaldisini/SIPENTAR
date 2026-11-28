import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../models/budidaya/budidaya_model.dart';

/// Service untuk mengakses data budidaya pada backend SIPENTAR.
///
/// Endpoint yang digunakan:
/// - GET    /budidaya
/// - POST   /budidaya
/// - GET    /budidaya/{id}
/// - PUT    /budidaya/{id}
/// - DELETE /budidaya/{id}
///
/// Seluruh endpoint budidaya memerlukan autentikasi Sanctum.
class BudidayaService {
  final ApiClient _apiClient;

  BudidayaService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static const String _endpoint = '/budidaya';

  Future<String> _getToken() async {
    final token = await TokenStorage.getToken();

    if (token == null || token.trim().isEmpty) {
      throw const BudidayaServiceException(
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
    String fallback = 'Permintaan data budidaya gagal.',
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
      throw BudidayaServiceException(
        message: _messageFromResponse(
          responseJson,
          fallback: fallbackMessage,
        ),
        statusCode: statusCode,
      );
    }

    if (apiSuccess != null && apiSuccess != true) {
      throw BudidayaServiceException(
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

    throw const FormatException('Data budidaya dari server tidak ditemukan.');
  }

  List<BudidayaModel> _parseBudidayaList(dynamic rawList) {
    if (rawList is! List) {
      throw const FormatException('Daftar budidaya dari server tidak valid.');
    }

    return rawList.map((item) {
      if (item is! Map) {
        throw const FormatException('Format item budidaya tidak valid.');
      }

      return BudidayaModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  /// Mengambil daftar budidaya beserta informasi pagination.
  ///
  /// Filter yang didukung backend:
  /// - [mejaId]
  /// - [status]: `berjalan` atau `selesai`
  /// - [from] dan [to]: rentang tanggal semai
  Future<BudidayaPageResult> getBudidayasPage({
    int page = 1,
    int perPage = 15,
    int? mejaId,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    if (page < 1 || perPage < 1) {
      throw ArgumentError('page dan perPage harus lebih besar dari 0.');
    }

    if (mejaId != null && mejaId < 1) {
      throw ArgumentError.value(
        mejaId,
        'mejaId',
        'ID meja harus lebih besar dari 0.',
      );
    }

    if (status != null &&
        status != BudidayaModel.statusBerjalan &&
        status != BudidayaModel.statusSelesai) {
      throw ArgumentError.value(
        status,
        'status',
        'Status harus berupa berjalan atau selesai.',
      );
    }

    if (from != null && to != null && _dateOnly(from).isAfter(_dateOnly(to))) {
      throw ArgumentError('Tanggal awal tidak boleh melewati tanggal akhir.');
    }

    final token = await _getToken();
    final queryParameters = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (mejaId != null) queryParameters['meja_id'] = mejaId.toString();
    if (status != null) queryParameters['status'] = status;
    if (from != null) queryParameters['from'] = _formatDate(from);
    if (to != null) queryParameters['to'] = _formatDate(to);

    final response = await _apiClient.get(
      _endpoint,
      queryParameters: queryParameters,
      token: token,
    );

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal mengambil daftar budidaya.',
    );

    // ApiResponse membungkus hasil ResourceCollection di dalam `data`.
    // Di dalamnya pagination Laravel memiliki `data` dan `meta`.
    final payload = _extractPayload(responseJson);
    final budidayas = _parseBudidayaList(payload['data']);
    final rawMeta = payload['meta'];
    final meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : <String, dynamic>{};

    return BudidayaPageResult(
      budidayas: budidayas,
      currentPage: _readInt(meta['current_page'], fallback: page),
      lastPage: _readInt(meta['last_page'], fallback: page),
      perPage: _readInt(meta['per_page'], fallback: perPage),
      total: _readInt(meta['total'], fallback: budidayas.length),
    );
  }

  /// Mengambil halaman pertama daftar budidaya.
  Future<List<BudidayaModel>> getBudidayas({
    int perPage = 15,
    int? mejaId,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await getBudidayasPage(
      page: 1,
      perPage: perPage,
      mejaId: mejaId,
      status: status,
      from: from,
      to: to,
    );

    return result.budidayas;
  }

  /// Mengambil detail budidaya berdasarkan ID.
  Future<BudidayaModel> getBudidayaById({required int id}) async {
    if (id < 1) {
      throw ArgumentError.value(id, 'id', 'ID budidaya harus lebih besar dari 0.');
    }

    final token = await _getToken();
    final response = await _apiClient.get('$_endpoint/$id', token: token);

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal mengambil detail budidaya.',
    );

    return BudidayaModel.fromJson(_extractPayload(responseJson));
  }

  /// Membuat budidaya baru.
  ///
  /// Backend mengisi `user_id` dari sesi login. Payload hanya berisi
  /// `meja_id`, `tanggal_semai`, `jumlah_tanaman`, dan `status`.
  Future<BudidayaModel> createBudidaya({
    required int mejaId,
    required DateTime tanggalSemai,
    required int jumlahTanaman,
    String status = BudidayaModel.statusBerjalan,
  }) async {
    _validateRequestFields(
      mejaId: mejaId,
      tanggalSemai: tanggalSemai,
      jumlahTanaman: jumlahTanaman,
      status: status,
    );

    final token = await _getToken();
    final response = await _apiClient.post(
      _endpoint,
      body: _buildRequestBody(
        mejaId: mejaId,
        tanggalSemai: tanggalSemai,
        jumlahTanaman: jumlahTanaman,
        status: status,
      ),
      token: token,
    );

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal menambahkan data budidaya.',
    );

    return BudidayaModel.fromJson(_extractPayload(responseJson));
  }

  /// Memperbarui budidaya berdasarkan ID.
  ///
  /// Request backend mewajibkan seluruh field budidaya dikirim pada PUT.
  Future<BudidayaModel> updateBudidaya({
    required int id,
    required int mejaId,
    required DateTime tanggalSemai,
    required int jumlahTanaman,
    required String status,
  }) async {
    if (id < 1) {
      throw ArgumentError.value(id, 'id', 'ID budidaya harus lebih besar dari 0.');
    }

    _validateRequestFields(
      mejaId: mejaId,
      tanggalSemai: tanggalSemai,
      jumlahTanaman: jumlahTanaman,
      status: status,
    );

    final token = await _getToken();
    final response = await _apiClient.put(
      '$_endpoint/$id',
      body: _buildRequestBody(
        mejaId: mejaId,
        tanggalSemai: tanggalSemai,
        jumlahTanaman: jumlahTanaman,
        status: status,
      ),
      token: token,
    );

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal memperbarui data budidaya.',
    );

    return BudidayaModel.fromJson(_extractPayload(responseJson));
  }

  /// Menghapus budidaya.
  ///
  /// Backend menolak penghapusan budidaya berstatus `selesai` atau yang
  /// sudah mempunyai data panen (HTTP 409).
  Future<void> deleteBudidaya({required int id}) async {
    if (id < 1) {
      throw ArgumentError.value(id, 'id', 'ID budidaya harus lebih besar dari 0.');
    }

    final token = await _getToken();
    final response = await _apiClient.delete('$_endpoint/$id', token: token);

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal menghapus data budidaya.',
    );
  }

  void _validateRequestFields({
    required int mejaId,
    required DateTime tanggalSemai,
    required int jumlahTanaman,
    required String status,
  }) {
    if (mejaId < 1) {
      throw ArgumentError.value(
        mejaId,
        'mejaId',
        'Meja tanam harus dipilih.',
      );
    }

    if (jumlahTanaman < 1) {
      throw ArgumentError.value(
        jumlahTanaman,
        'jumlahTanaman',
        'Jumlah tanaman minimal 1.',
      );
    }

    if (status != BudidayaModel.statusBerjalan &&
        status != BudidayaModel.statusSelesai) {
      throw ArgumentError.value(
        status,
        'status',
        'Status harus berupa berjalan atau selesai.',
      );
    }

    final today = _dateOnly(DateTime.now());
    if (_dateOnly(tanggalSemai).isAfter(today)) {
      throw ArgumentError.value(
        tanggalSemai,
        'tanggalSemai',
        'Tanggal semai tidak boleh di masa depan.',
      );
    }
  }

  Map<String, dynamic> _buildRequestBody({
    required int mejaId,
    required DateTime tanggalSemai,
    required int jumlahTanaman,
    required String status,
  }) {
    return {
      'meja_id': mejaId,
      'tanggal_semai': _formatDate(tanggalSemai),
      'jumlah_tanaman': jumlahTanaman,
      'status': status,
    };
  }

  int _readInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void dispose() {
    _apiClient.dispose();
  }
}

/// Hasil daftar budidaya dengan metadata pagination Laravel.
class BudidayaPageResult {
  final List<BudidayaModel> budidayas;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const BudidayaPageResult({
    required this.budidayas,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

/// Error terstruktur dari service budidaya.
class BudidayaServiceException implements Exception {
  final String message;
  final int? statusCode;

  const BudidayaServiceException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}
