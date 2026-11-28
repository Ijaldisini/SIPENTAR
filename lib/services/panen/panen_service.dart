import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../models/panen/panen_model.dart';

/// Service untuk mengakses data panen pada backend SIPENTAR.
///
/// Endpoint yang digunakan:
/// - GET    /panen
/// - POST   /panen
/// - GET    /panen/{id}
/// - PUT    /panen/{id}
/// - DELETE /panen/{id}
///
/// Seluruh endpoint panen memerlukan autentikasi Sanctum.
class PanenService {
  final ApiClient _apiClient;

  PanenService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static const String _endpoint = '/panen';

  Future<String> _getToken() async {
    final token = await TokenStorage.getToken();

    if (token == null || token.trim().isEmpty) {
      throw const PanenServiceException(
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
    String fallback = 'Permintaan data panen gagal.',
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
      throw PanenServiceException(
        message: _messageFromResponse(responseJson, fallback: fallbackMessage),
        statusCode: statusCode,
      );
    }

    if (apiSuccess != null && apiSuccess != true) {
      throw PanenServiceException(
        message: fallbackMessage,
        statusCode: statusCode,
      );
    }
  }

  Map<String, dynamic> _extractPayload(Map<String, dynamic> responseJson) {
    final rawData = responseJson['data'];

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    throw const FormatException('Data panen dari server tidak ditemukan.');
  }

  List<PanenModel> _parsePanenList(dynamic rawList) {
    if (rawList is! List) {
      throw const FormatException('Daftar panen dari server tidak valid.');
    }

    return rawList.map((item) {
      if (item is! Map) {
        throw const FormatException('Format item panen tidak valid.');
      }

      return PanenModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  /// Mengambil daftar panen beserta metadata pagination Laravel.
  ///
  /// Filter yang didukung backend:
  /// - [budidayaId]
  /// - [mejaId]
  /// - [status]: `terjadwal` atau `selesai`
  /// - [from] dan [to]: rentang tanggal panen
  Future<PanenPageResult> getPanensPage({
    int page = 1,
    int perPage = 15,
    int? budidayaId,
    int? mejaId,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    if (page < 1 || perPage < 1) {
      throw ArgumentError('page dan perPage harus lebih besar dari 0.');
    }

    if (budidayaId != null && budidayaId < 1) {
      throw ArgumentError.value(
        budidayaId,
        'budidayaId',
        'ID budidaya harus lebih besar dari 0.',
      );
    }

    if (mejaId != null && mejaId < 1) {
      throw ArgumentError.value(
        mejaId,
        'mejaId',
        'ID meja harus lebih besar dari 0.',
      );
    }

    if (status != null &&
        status != PanenModel.statusTerjadwal &&
        status != PanenModel.statusSelesai) {
      throw ArgumentError.value(
        status,
        'status',
        'Status harus berupa terjadwal atau selesai.',
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

    if (budidayaId != null) {
      queryParameters['budidaya_id'] = budidayaId.toString();
    }
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
      fallbackMessage: 'Gagal mengambil daftar panen.',
    );

    // ApiResponse membungkus ResourceCollection di dalam `data`.
    // Data pagination Laravel berada di payload.data dan payload.meta.
    final payload = _extractPayload(responseJson);
    final panens = _parsePanenList(payload['data']);
    final rawMeta = payload['meta'];
    final meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : <String, dynamic>{};

    return PanenPageResult(
      panens: panens,
      currentPage: _readInt(meta['current_page'], fallback: page),
      lastPage: _readInt(meta['last_page'], fallback: page),
      perPage: _readInt(meta['per_page'], fallback: perPage),
      total: _readInt(meta['total'], fallback: panens.length),
    );
  }

  /// Mengambil daftar panen pada halaman pertama.
  Future<List<PanenModel>> getPanens({
    int perPage = 15,
    int? budidayaId,
    int? mejaId,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await getPanensPage(
      page: 1,
      perPage: perPage,
      budidayaId: budidayaId,
      mejaId: mejaId,
      status: status,
      from: from,
      to: to,
    );

    return result.panens;
  }

  /// Mengambil detail panen berdasarkan ID.
  Future<PanenModel> getPanenById({required int id}) async {
    if (id < 1) {
      throw ArgumentError.value(id, 'id', 'ID panen harus lebih besar dari 0.');
    }

    final token = await _getToken();
    final response = await _apiClient.get('$_endpoint/$id', token: token);

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal mengambil detail panen.',
    );

    return PanenModel.fromJson(_extractPayload(responseJson));
  }

  /// Membuat jadwal panen atau mencatat panen selesai.
  ///
  /// Backend meminta `budidaya_id`, `tanggal_panen`, dan `status`.
  /// `berat_kg` boleh null untuk status `terjadwal`, tetapi wajib diisi
  /// minimal 0.01 ketika status `selesai`.
  Future<PanenModel> createPanen({
    required int budidayaId,
    required DateTime tanggalPanen,
    required String status,
    double? beratKg,
  }) async {
    _validateRequestFields(
      budidayaId: budidayaId,
      status: status,
      beratKg: beratKg,
    );

    final token = await _getToken();
    final response = await _apiClient.post(
      _endpoint,
      body: _buildRequestBody(
        budidayaId: budidayaId,
        tanggalPanen: tanggalPanen,
        status: status,
        beratKg: beratKg,
      ),
      token: token,
    );

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal menambahkan data panen.',
    );

    return PanenModel.fromJson(_extractPayload(responseJson));
  }

  /// Memperbarui data panen berdasarkan ID.
  ///
  /// Backend memvalidasi tanggal panen terhadap tanggal semai budidaya,
  /// serta keunikan tanggal panen untuk meja tanam terkait.
  Future<PanenModel> updatePanen({
    required int id,
    required int budidayaId,
    required DateTime tanggalPanen,
    required String status,
    double? beratKg,
  }) async {
    if (id < 1) {
      throw ArgumentError.value(id, 'id', 'ID panen harus lebih besar dari 0.');
    }

    _validateRequestFields(
      budidayaId: budidayaId,
      status: status,
      beratKg: beratKg,
    );

    final token = await _getToken();
    final response = await _apiClient.put(
      '$_endpoint/$id',
      body: _buildRequestBody(
        budidayaId: budidayaId,
        tanggalPanen: tanggalPanen,
        status: status,
        beratKg: beratKg,
      ),
      token: token,
    );

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal memperbarui data panen.',
    );

    return PanenModel.fromJson(_extractPayload(responseJson));
  }

  /// Menghapus data panen berdasarkan ID.
  Future<void> deletePanen({required int id}) async {
    if (id < 1) {
      throw ArgumentError.value(id, 'id', 'ID panen harus lebih besar dari 0.');
    }

    final token = await _getToken();
    final response = await _apiClient.delete('$_endpoint/$id', token: token);

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal menghapus data panen.',
    );
  }

  void _validateRequestFields({
    required int budidayaId,
    required String status,
    required double? beratKg,
  }) {
    if (budidayaId < 1) {
      throw ArgumentError.value(
        budidayaId,
        'budidayaId',
        'Budidaya harus dipilih.',
      );
    }

    if (status != PanenModel.statusTerjadwal &&
        status != PanenModel.statusSelesai) {
      throw ArgumentError.value(
        status,
        'status',
        'Status harus berupa terjadwal atau selesai.',
      );
    }

    if (status == PanenModel.statusSelesai && beratKg == null) {
      throw ArgumentError('Berat panen wajib diisi ketika status selesai.');
    }

    if (beratKg != null && !PanenModel.isValidBeratKg(beratKg)) {
      throw ArgumentError.value(
        beratKg,
        'beratKg',
        'Berat panen harus berupa angka valid dan minimal 0.01 kg.',
      );
    }
  }

  Map<String, dynamic> _buildRequestBody({
    required int budidayaId,
    required DateTime tanggalPanen,
    required String status,
    required double? beratKg,
  }) {
    return {
      'budidaya_id': budidayaId,
      'tanggal_panen': _formatDate(tanggalPanen),
      'berat_kg': beratKg,
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

/// Hasil daftar panen dengan metadata pagination Laravel.
class PanenPageResult {
  final List<PanenModel> panens;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PanenPageResult({
    required this.panens,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

/// Error terstruktur dari service panen.
class PanenServiceException implements Exception {
  final String message;
  final int? statusCode;

  const PanenServiceException({required this.message, this.statusCode});

  @override
  String toString() => message;
}
