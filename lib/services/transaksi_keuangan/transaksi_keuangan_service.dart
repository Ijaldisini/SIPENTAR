import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../models/transaksi_keuangan/transaksi_keuangan_model.dart';
import '../../models/transaksi_keuangan/laporan_keuangan_model.dart';

/// Service untuk berkomunikasi dengan endpoint transaksi keuangan SIPENTAR.
///
/// Semua endpoint transaksi keuangan dibatasi untuk role pemilik pada backend.
class TransaksiKeuanganService {
  final ApiClient _apiClient;

  TransaksiKeuanganService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static const String _endpoint = '/transaksi-keuangan';

  Future<String> _getToken() async {
    final token = await TokenStorage.getToken();

    if (token == null || token.trim().isEmpty) {
      throw const TransaksiKeuanganServiceException(
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
    String fallback = 'Permintaan transaksi keuangan gagal.',
  }) {
    // Laravel mengirim detail validasi dalam object "errors".
    final errors = responseJson['errors'];
    if (errors is Map) {
      final validationMessages = <String>[];

      for (final value in errors.values) {
        if (value is List) {
          validationMessages.addAll(value.whereType<String>());
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
      throw TransaksiKeuanganServiceException(
        message: _messageFromResponse(
          responseJson,
          fallback: fallbackMessage,
        ),
        statusCode: statusCode,
      );
    }

    if (apiSuccess != null && apiSuccess != true) {
      throw TransaksiKeuanganServiceException(
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

    throw const FormatException('Data transaksi dari server tidak ditemukan.');
  }

  List<TransaksiKeuanganModel> _parseTransactionList(dynamic rawList) {
    if (rawList is! List) {
      throw const FormatException('Daftar transaksi dari server tidak valid.');
    }

    return rawList.map((item) {
      if (item is! Map) {
        throw const FormatException('Format item transaksi tidak valid.');
      }

      return TransaksiKeuanganModel.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  /// Mengambil transaksi dengan paginasi dan filter opsional.
  ///
  /// Parameter [jenis] menerima `pemasukan` atau `pengeluaran`.
  /// [from] dan [to] dikirim ke backend dengan format YYYY-MM-DD.
  Future<TransaksiKeuanganPageResult> getTransaksiKeuanganPage({
    int page = 1,
    int perPage = 15,
    String? jenis,
    DateTime? from,
    DateTime? to,
  }) async {
    if (page < 1 || perPage < 1) {
      throw ArgumentError('page dan perPage harus lebih besar dari 0.');
    }

    if (jenis != null && jenis != 'pemasukan' && jenis != 'pengeluaran') {
      throw ArgumentError.value(
        jenis,
        'jenis',
        'Harus berupa pemasukan atau pengeluaran.',
      );
    }

    final token = await _getToken();
    final queryParameters = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (jenis != null) queryParameters['jenis'] = jenis;
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
      fallbackMessage: 'Gagal mengambil daftar transaksi keuangan.',
    );

    final payload = _extractPayload(responseJson);
    final transactions = _parseTransactionList(payload['data']);
    final meta = payload['meta'] is Map
        ? Map<String, dynamic>.from(payload['meta'] as Map)
        : <String, dynamic>{};

    return TransaksiKeuanganPageResult(
      transactions: transactions,
      currentPage: _readInt(meta['current_page'], fallback: page),
      lastPage: _readInt(meta['last_page'], fallback: page),
      perPage: _readInt(meta['per_page'], fallback: perPage),
      total: _readInt(meta['total'], fallback: transactions.length),
    );
  }

  /// Mengambil ringkasan laporan keuangan untuk rentang tanggal tertentu.
  /// Endpoint ini hanya dapat diakses role `pemilik`.
  Future<LaporanKeuanganModel> getLaporanKeuangan({
    required DateTime from,
    required DateTime to,
  }) async {
    if (_dateOnly(from).isAfter(_dateOnly(to))) {
      throw ArgumentError('Tanggal awal tidak boleh melewati tanggal akhir.');
    }

    final token = await _getToken();
    final response = await _apiClient.get(
      '/keuangan/laporan',
      queryParameters: {
        'from': _formatDate(from),
        'to': _formatDate(to),
      },
      token: token,
    );

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal mengambil ringkasan laporan keuangan.',
    );

    final payload = _extractPayload(responseJson);
    return LaporanKeuanganModel.fromJson(payload);
  }

  /// Mengambil daftar transaksi halaman pertama.
  Future<List<TransaksiKeuanganModel>> getTransaksiKeuangan({
    int perPage = 15,
    String? jenis,
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await getTransaksiKeuanganPage(
      page: 1,
      perPage: perPage,
      jenis: jenis,
      from: from,
      to: to,
    );

    return result.transactions;
  }

  /// Mengambil detail satu transaksi berdasarkan ID.
  Future<TransaksiKeuanganModel> getTransaksiKeuanganById({
    required int id,
  }) async {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'ID tidak valid.');

    final token = await _getToken();
    final response = await _apiClient.get('$_endpoint/$id', token: token);
    final responseJson = _decodeResponse(response.body);

    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal mengambil detail transaksi keuangan.',
    );

    return TransaksiKeuanganModel.fromJson(_extractPayload(responseJson));
  }

  /// Membuat transaksi baru.
  ///
  /// Untuk `pemasukan`, [persentaseKas] wajib diisi dan validasinya tetap
  /// mengikuti konfigurasi minimum/maksimum yang diterapkan backend.
  Future<TransaksiKeuanganModel> createTransaksiKeuangan({
    required String jenis,
    required DateTime tanggal,
    required double jumlah,
    int? panenId,
    double? persentaseKas,
    String? keterangan,
  }) async {
    _validateRequest(
      jenis: jenis,
      jumlah: jumlah,
      persentaseKas: persentaseKas,
    );

    final token = await _getToken();
    final response = await _apiClient.post(
      _endpoint,
      token: token,
      body: _buildRequestBody(
        jenis: jenis,
        tanggal: tanggal,
        jumlah: jumlah,
        panenId: panenId,
        persentaseKas: persentaseKas,
        keterangan: keterangan,
      ),
    );

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal menyimpan transaksi keuangan.',
    );

    return TransaksiKeuanganModel.fromJson(_extractPayload(responseJson));
  }

  /// Memperbarui transaksi yang sudah ada.
  ///
  /// Backend mensyaratkan field `jenis`, `tanggal`, dan `jumlah` pada PUT.
  Future<TransaksiKeuanganModel> updateTransaksiKeuangan({
    required int id,
    required String jenis,
    required DateTime tanggal,
    required double jumlah,
    int? panenId,
    double? persentaseKas,
    String? keterangan,
  }) async {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'ID tidak valid.');

    _validateRequest(
      jenis: jenis,
      jumlah: jumlah,
      persentaseKas: persentaseKas,
    );

    final token = await _getToken();
    final response = await _apiClient.put(
      '$_endpoint/$id',
      token: token,
      body: _buildRequestBody(
        jenis: jenis,
        tanggal: tanggal,
        jumlah: jumlah,
        panenId: panenId,
        persentaseKas: persentaseKas,
        keterangan: keterangan,
      ),
    );

    final responseJson = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      responseJson,
      fallbackMessage: 'Gagal memperbarui transaksi keuangan.',
    );

    return TransaksiKeuanganModel.fromJson(_extractPayload(responseJson));
  }

  void _validateRequest({
    required String jenis,
    required double jumlah,
    required double? persentaseKas,
  }) {
    if (jenis != 'pemasukan' && jenis != 'pengeluaran') {
      throw ArgumentError.value(
        jenis,
        'jenis',
        'Harus berupa pemasukan atau pengeluaran.',
      );
    }

    if (!jumlah.isFinite || jumlah < 0) {
      throw ArgumentError.value(jumlah, 'jumlah', 'Jumlah tidak valid.');
    }

    if (persentaseKas != null && !persentaseKas.isFinite) {
      throw ArgumentError.value(
        persentaseKas,
        'persentaseKas',
        'Persentase kas tidak valid.',
      );
    }

    if (jenis == 'pemasukan' && persentaseKas == null) {
      throw ArgumentError('Persentase kas wajib diisi untuk pemasukan.');
    }
  }

  Map<String, dynamic> _buildRequestBody({
    required String jenis,
    required DateTime tanggal,
    required double jumlah,
    required int? panenId,
    required double? persentaseKas,
    required String? keterangan,
  }) {
    final normalizedKeterangan = keterangan?.trim();

    return {
      'jenis': jenis,
      'tanggal': _formatDate(tanggal),
      'jumlah': jumlah,
      'panen_id': panenId,
      'persentase_kas': jenis == 'pemasukan' ? persentaseKas : null,
      'keterangan':
          normalizedKeterangan == null || normalizedKeterangan.isEmpty
          ? null
          : normalizedKeterangan,
    };
  }

  int _readInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void dispose() {
    _apiClient.dispose();
  }
}

class TransaksiKeuanganPageResult {
  final List<TransaksiKeuanganModel> transactions;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const TransaksiKeuanganPageResult({
    required this.transactions,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

class TransaksiKeuanganServiceException implements Exception {
  final String message;
  final int? statusCode;

  const TransaksiKeuanganServiceException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}
