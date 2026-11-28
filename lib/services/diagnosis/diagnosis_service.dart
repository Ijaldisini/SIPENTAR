import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/storage/token_storage.dart';
import '../../models/diagnosis/diagnosis_model.dart';

/// Service untuk mengakses diagnosis kesehatan tanaman pada backend SIPENTAR.
///
/// Endpoint yang digunakan:
/// - GET  /diagnosis
/// - POST /diagnosis (multipart/form-data)
/// - GET  /diagnosis/{id}
///
/// Seluruh endpoint memerlukan token Laravel Sanctum.
/// Backend menerima satu file `image` dan satu field `budidaya_id`.
class DiagnosisService {
  final ApiClient _apiClient;
  final http.Client _multipartClient;
  final bool _ownsMultipartClient;

  DiagnosisService({
    ApiClient? apiClient,
    http.Client? multipartClient,
  }) : _apiClient = apiClient ?? ApiClient(),
       _multipartClient = multipartClient ?? http.Client(),
       _ownsMultipartClient = multipartClient == null;

  static const String _endpoint = '/diagnosis';
  static const int _maxImageBytes = 5 * 1024 * 1024;
  static const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png'};

  Future<String> _getToken() async {
    final token = await TokenStorage.getToken();

    if (token == null || token.trim().isEmpty) {
      throw const DiagnosisServiceException(
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
    String fallback = 'Permintaan diagnosis gagal.',
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
      throw DiagnosisServiceException(
        message: _messageFromResponse(
          responseJson,
          fallback: fallbackMessage,
        ),
        statusCode: statusCode,
      );
    }

    if (apiSuccess != null && apiSuccess != true) {
      throw DiagnosisServiceException(
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

    throw const FormatException('Data diagnosis dari server tidak ditemukan.');
  }

  List<DiagnosisModel> _parseDiagnosisList(dynamic rawList) {
    if (rawList is! List) {
      throw const FormatException('Daftar diagnosis dari server tidak valid.');
    }

    return rawList.map((item) {
      if (item is! Map) {
        throw const FormatException('Format item diagnosis tidak valid.');
      }

      return DiagnosisModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  /// Mengambil daftar diagnosis dengan pagination Laravel.
  ///
  /// Filter yang didukung backend: [budidayaId], [hasil], [from], dan [to].
  /// Nilai [hasil] harus salah satu kelas diagnosis yang disediakan backend.
  Future<DiagnosisPageResult> getDiagnosesPage({
    int page = 1,
    int perPage = 15,
    int? budidayaId,
    String? hasil,
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

    if (hasil != null &&
        hasil != DiagnosisModel.hasilSehat &&
        hasil != DiagnosisModel.hasilBusukBatang &&
        hasil != DiagnosisModel.hasilCacarDaun &&
        hasil != DiagnosisModel.hasilBusukAkar) {
      throw ArgumentError.value(
        hasil,
        'hasil',
        'Hasil diagnosis tidak dikenali.',
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
    if (hasil != null) queryParameters['hasil'] = hasil;
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
      fallbackMessage: 'Gagal mengambil daftar diagnosis.',
    );

    // ApiResponse membungkus hasil pagination Laravel di dalam `data`.
    final payload = _extractPayload(responseJson);
    final diagnoses = _parseDiagnosisList(payload['data']);
    final rawMeta = payload['meta'];
    final meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : <String, dynamic>{};

    return DiagnosisPageResult(
      diagnoses: diagnoses,
      currentPage: _readInt(meta['current_page'], fallback: page),
      lastPage: _readInt(meta['last_page'], fallback: page),
      perPage: _readInt(meta['per_page'], fallback: perPage),
      total: _readInt(meta['total'], fallback: diagnoses.length),
    );
  }

  /// Mengambil daftar diagnosis pada halaman pertama.
  Future<List<DiagnosisModel>> getDiagnoses({
    int perPage = 15,
    int? budidayaId,
    String? hasil,
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await getDiagnosesPage(
      page: 1,
      perPage: perPage,
      budidayaId: budidayaId,
      hasil: hasil,
      from: from,
      to: to,
    );

    return result.diagnoses;
  }

  /// Mengambil satu detail diagnosis berdasarkan ID.
  Future<DiagnosisModel> getDiagnosisById({required int id}) async {
    if (id < 1) {
      throw ArgumentError.value(
        id,
        'id',
        'ID diagnosis harus lebih besar dari 0.',
      );
    }

    final token = await _getToken();
    final response = await _apiClient.get('$_endpoint/$id', token: token);

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal mengambil detail diagnosis.',
    );

    return DiagnosisModel.fromJson(_extractPayload(responseJson));
  }

  /// Mengunggah satu foto untuk diperiksa oleh backend.
  ///
  /// Request multipart hanya berisi field `image` dan `budidaya_id`.
  /// `user_id` serta `tanggal_diagnosis` diisi otomatis oleh backend.
  Future<DiagnosisModel> createDiagnosis({
    required File image,
    required int budidayaId,
  }) async {
    if (budidayaId < 1) {
      throw ArgumentError.value(
        budidayaId,
        'budidayaId',
        'Budidaya harus dipilih.',
      );
    }

    final extension = image.path.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(extension)) {
      throw ArgumentError.value(
        image.path,
        'image',
        'Foto harus berformat JPG, JPEG, atau PNG.',
      );
    }

    final int imageLength;
    try {
      imageLength = await image.length();
    } on FileSystemException {
      throw ArgumentError.value(
        image.path,
        'image',
        'File foto tidak dapat dibaca. Silakan pilih ulang foto.',
      );
    }

    if (imageLength <= 0) {
      throw ArgumentError('File foto kosong. Silakan pilih foto lain.');
    }

    if (imageLength > _maxImageBytes) {
      throw ArgumentError('Ukuran foto maksimal 5 MB.');
    }

    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}$_endpoint'),
    )
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['budidaya_id'] = budidayaId.toString()
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    try {
      final streamedResponse = await _multipartClient
          .send(request)
          .timeout(ApiConfig.connectionTimeout);
      final response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(ApiConfig.connectionTimeout);

      final responseJson = _decodeResponse(response.body);
      _checkResponse(
        response.statusCode,
        responseJson,
        fallbackMessage: 'Gagal mengirim foto untuk diagnosis.',
      );

      return DiagnosisModel.fromJson(_extractPayload(responseJson));
    } on TimeoutException {
      throw const DiagnosisServiceException(
        message: 'Upload foto melewati batas waktu. Silakan coba lagi.',
      );
    } on SocketException {
      throw const DiagnosisServiceException(
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    } on http.ClientException {
      throw const DiagnosisServiceException(
        message: 'Upload foto gagal karena koneksi ke server terputus.',
      );
    }
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
    if (_ownsMultipartClient) {
      _multipartClient.close();
    }
  }
}

/// Hasil daftar diagnosis beserta metadata pagination Laravel.
class DiagnosisPageResult {
  final List<DiagnosisModel> diagnoses;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const DiagnosisPageResult({
    required this.diagnoses,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

/// Error terstruktur dari service diagnosis.
class DiagnosisServiceException implements Exception {
  final String message;
  final int? statusCode;

  const DiagnosisServiceException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}
