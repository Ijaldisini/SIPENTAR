import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../models/auth/user_model.dart';
import '../../models/budidaya/budidaya_model.dart';
import '../../models/dashboard/dashboard_summary_model.dart';
import '../../models/diagnosis/diagnosis_model.dart';
import '../../models/panen/panen_model.dart';
import '../../models/transaksi_keuangan/laporan_keuangan_model.dart';

/// Menggabungkan beberapa endpoint modul menjadi satu ringkasan Beranda.
///
/// Backend belum menyediakan endpoint `/dashboard`, sehingga service ini
/// membaca endpoint resmi masing-masing modul. Semua request menggunakan
/// token Laravel Sanctum dari [TokenStorage].
///
/// Untuk role `pegawai`, endpoint `/keuangan/laporan` dan `/karyawan` tidak
/// dipanggil karena keduanya dibatasi untuk role `pemilik` di backend.
class DashboardService {
  final ApiClient _apiClient;
  final bool _ownsApiClient;

  DashboardService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _ownsApiClient = apiClient == null;

  static const int _pageSize = 100;
  static const int _employeePreviewSize = 3;

  /// Mengambil dan menyusun seluruh ringkasan dashboard untuk role pengguna.
  ///
  /// Rentang laporan keuangan dimulai dari tanggal 1 bulan berjalan sampai
  /// [referenceDate]. Statistik diagnosis difilter pada tanggal [referenceDate].
  Future<DashboardSummaryModel> getDashboardSummary({
    required String role,
    DateTime? referenceDate,
  }) async {
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole != 'pemilik' && normalizedRole != 'pegawai') {
      throw ArgumentError.value(
        role,
        'role',
        'Role pengguna harus berupa pemilik atau pegawai.',
      );
    }

    final token = await _getToken();
    final reference = _dateOnly(referenceDate ?? DateTime.now());

    final activeCultivationsFuture = _fetchAllPaginated<BudidayaModel>(
      endpoint: '/budidaya',
      token: token,
      queryParameters: const {'status': BudidayaModel.statusBerjalan},
      parser: BudidayaModel.fromJson,
      resourceLabel: 'budidaya',
    );

    final upcomingHarvestsFuture = _fetchAllPaginated<PanenModel>(
      endpoint: '/panen',
      token: token,
      queryParameters: {
        'status': PanenModel.statusTerjadwal,
        'from': _formatDate(reference),
      },
      parser: PanenModel.fromJson,
      resourceLabel: 'panen',
    );

    final stockPageFuture = _fetchPaginatedPage(
      endpoint: '/stok',
      token: token,
      page: 1,
      perPage: 1,
    );

    final lowStockFuture = _fetchArray(
      endpoint: '/notifikasi',
      token: token,
      resourceLabel: 'notifikasi stok',
    );

    final diagnosisFuture = _fetchAllPaginated<DiagnosisModel>(
      endpoint: '/diagnosis',
      token: token,
      queryParameters: {
        'from': _formatDate(reference),
        'to': _formatDate(reference),
      },
      parser: DiagnosisModel.fromJson,
      resourceLabel: 'diagnosis',
    );

    final futures = <Future<Object>>[
      activeCultivationsFuture,
      upcomingHarvestsFuture,
      stockPageFuture,
      lowStockFuture,
      diagnosisFuture,
    ];

    // Endpoint keuangan dan karyawan hanya diakses pemilik.
    if (normalizedRole == 'pemilik') {
      final monthStart = DateTime(reference.year, reference.month, 1);
      futures.add(
        _fetchFinancialReport(token: token, from: monthStart, to: reference),
      );
      futures.add(_fetchEmployeePreview(token: token));
    }

    final results = await Future.wait<Object>(futures);

    final cultivations = results[0] as _AllPagesResult<BudidayaModel>;
    final harvests = results[1] as _AllPagesResult<PanenModel>;
    final stockPage = results[2] as _PaginatedPage;
    final lowStockItems = results[3] as List<dynamic>;
    final diagnoses = results[4] as _AllPagesResult<DiagnosisModel>;

    final cultivationSummary = _buildCultivationSummary(
      cultivations: cultivations,
      harvests: harvests,
      referenceDate: reference,
    );

    final stockSummary = DashboardStokSummary(
      totalJenisBarang: stockPage.total,
      totalStokHampirHabis: lowStockItems.length,
    );

    final normalCount = diagnoses.items.where((item) => item.isSehat).length;
    final healthSummary = DashboardKesehatanSummary(
      totalPemeriksaan: diagnoses.items.length,
      totalNormal: normalCount,
      totalPerluPantau: diagnoses.items.length - normalCount,
    );

    DashboardKeuanganSummary? financialSummary;
    DashboardKaryawanSummary? employeeSummary;

    if (normalizedRole == 'pemilik') {
      financialSummary = DashboardKeuanganSummary(
        laporan: results[5] as LaporanKeuanganModel,
      );
      employeeSummary = results[6] as DashboardKaryawanSummary;
    }

    return DashboardSummaryModel(
      tanggalReferensi: reference,
      budidaya: cultivationSummary,
      keuangan: financialSummary,
      stok: stockSummary,
      kesehatan: healthSummary,
      karyawan: employeeSummary,
    );
  }

  DashboardBudidayaSummary _buildCultivationSummary({
    required _AllPagesResult<BudidayaModel> cultivations,
    required _AllPagesResult<PanenModel> harvests,
    required DateTime referenceDate,
  }) {
    final active = [...cultivations.items];
    final upcoming = harvests.items.where((item) {
      return item.status == PanenModel.statusTerjadwal &&
          !_dateOnly(item.tanggalPanen).isBefore(referenceDate);
    }).toList()..sort((a, b) => a.tanggalPanen.compareTo(b.tanggalPanen));

    if (active.isEmpty) {
      return DashboardBudidayaSummary(
        budidayaUtama: null,
        totalBudidayaBerjalan: cultivations.total,
        panenBerikut: null,
      );
    }

    // Prioritaskan budidaya aktif yang mempunyai jadwal panen terdekat.
    BudidayaModel? selectedCultivation;
    PanenModel? selectedHarvest;

    for (final harvest in upcoming) {
      final match = active.where((item) => item.id == harvest.budidayaId);
      if (match.isNotEmpty) {
        selectedCultivation = match.first;
        selectedHarvest = harvest;
        break;
      }
    }

    // Jika belum ada jadwal panen yang cocok, tampilkan budidaya yang paling
    // lama berjalan (tanggal semai paling awal) sebagai budidaya utama.
    if (selectedCultivation == null) {
      active.sort((a, b) => a.tanggalSemai.compareTo(b.tanggalSemai));
      selectedCultivation = active.first;
      final matchingHarvests = upcoming
          .where((item) => item.budidayaId == selectedCultivation!.id)
          .toList();
      if (matchingHarvests.isNotEmpty) {
        selectedHarvest = matchingHarvests.first;
      }
    }

    return DashboardBudidayaSummary(
      budidayaUtama: selectedCultivation,
      totalBudidayaBerjalan: cultivations.total,
      panenBerikut: selectedHarvest,
    );
  }

  Future<LaporanKeuanganModel> _fetchFinancialReport({
    required String token,
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _apiClient.get(
      '/keuangan/laporan',
      token: token,
      queryParameters: {'from': _formatDate(from), 'to': _formatDate(to)},
    );

    final envelope = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      envelope,
      resourceLabel: 'laporan keuangan',
    );

    final payload = _extractMapData(
      envelope,
      resourceLabel: 'laporan keuangan',
    );
    return LaporanKeuanganModel.fromJson(payload);
  }

  Future<DashboardKaryawanSummary> _fetchEmployeePreview({
    required String token,
  }) async {
    final page = await _fetchPaginatedPage(
      endpoint: '/karyawan',
      token: token,
      page: 1,
      perPage: _employeePreviewSize,
      resourceLabel: 'karyawan',
    );

    final employees = _parseList<UserModel>(
      page.items,
      UserModel.fromJson,
      resourceLabel: 'karyawan',
    );

    return DashboardKaryawanSummary(
      totalKaryawan: page.total,
      karyawanPreview: employees,
    );
  }

  Future<_AllPagesResult<T>> _fetchAllPaginated<T>({
    required String endpoint,
    required String token,
    required Map<String, String> queryParameters,
    required T Function(Map<String, dynamic>) parser,
    required String resourceLabel,
  }) async {
    var pageNumber = 1;
    var lastPage = 1;
    var total = 0;
    final items = <T>[];

    do {
      final page = await _fetchPaginatedPage(
        endpoint: endpoint,
        token: token,
        page: pageNumber,
        perPage: _pageSize,
        queryParameters: queryParameters,
        resourceLabel: resourceLabel,
      );

      items.addAll(
        _parseList<T>(page.items, parser, resourceLabel: resourceLabel),
      );
      total = page.total;
      lastPage = page.lastPage;

      if (page.currentPage < pageNumber) {
        throw FormatException(
          'Pagination $resourceLabel tidak bergerak ke halaman yang diminta.',
        );
      }

      pageNumber = page.currentPage + 1;
    } while (pageNumber <= lastPage);

    return _AllPagesResult<T>(items: items, total: total);
  }

  Future<_PaginatedPage> _fetchPaginatedPage({
    required String endpoint,
    required String token,
    required int page,
    required int perPage,
    Map<String, String> queryParameters = const {},
    String? resourceLabel,
  }) async {
    final query = <String, String>{
      ...queryParameters,
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    final response = await _apiClient.get(
      endpoint,
      queryParameters: query,
      token: token,
    );

    final envelope = _decodeResponse(response.body);
    _checkResponse(
      response.statusCode,
      envelope,
      resourceLabel: resourceLabel ?? endpoint,
    );

    final payload = _extractMapData(
      envelope,
      resourceLabel: resourceLabel ?? endpoint,
    );
    final rawItems = payload['data'];
    if (rawItems is! List) {
      throw FormatException(
        'Daftar ${resourceLabel ?? endpoint} dari server tidak valid.',
      );
    }

    final rawMeta = payload['meta'];
    final meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : <String, dynamic>{};

    final currentPage = _readInt(meta['current_page'], fallback: page);
    final lastPage = _readInt(meta['last_page'], fallback: currentPage);
    final actualPerPage = _readInt(meta['per_page'], fallback: perPage);
    final total = _readInt(meta['total'], fallback: rawItems.length);

    if (currentPage < 1 || lastPage < currentPage || total < 0) {
      throw FormatException(
        'Metadata pagination ${resourceLabel ?? endpoint} tidak valid.',
      );
    }

    return _PaginatedPage(
      items: rawItems,
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: actualPerPage,
      total: total,
    );
  }

  Future<List<dynamic>> _fetchArray({
    required String endpoint,
    required String token,
    required String resourceLabel,
  }) async {
    final response = await _apiClient.get(endpoint, token: token);
    final envelope = _decodeResponse(response.body);
    _checkResponse(response.statusCode, envelope, resourceLabel: resourceLabel);

    final rawData = envelope['data'];
    if (rawData is! List) {
      throw FormatException('Data $resourceLabel dari server tidak valid.');
    }

    return rawData;
  }

  List<T> _parseList<T>(
    List<dynamic> rawItems,
    T Function(Map<String, dynamic>) parser, {
    required String resourceLabel,
  }) {
    return rawItems
        .map((item) {
          if (item is! Map) {
            throw FormatException('Format item $resourceLabel tidak valid.');
          }
          return parser(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);
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

  Map<String, dynamic> _extractMapData(
    Map<String, dynamic> envelope, {
    required String resourceLabel,
  }) {
    final rawData = envelope['data'];
    if (rawData is Map) return Map<String, dynamic>.from(rawData);
    throw FormatException('Data $resourceLabel dari server tidak ditemukan.');
  }

  void _checkResponse(
    int statusCode,
    Map<String, dynamic> envelope, {
    required String resourceLabel,
  }) {
    final apiSuccess = envelope['success'];
    if (statusCode >= 200 && statusCode < 300 && apiSuccess != false) {
      return;
    }

    final message = _messageFromResponse(
      envelope,
      fallback: 'Gagal mengambil data $resourceLabel.',
    );
    throw DashboardServiceException(
      message: message,
      statusCode: statusCode,
      resourceLabel: resourceLabel,
    );
  }

  String _messageFromResponse(
    Map<String, dynamic> envelope, {
    required String fallback,
  }) {
    final rawErrors = envelope['errors'];
    if (rawErrors is Map) {
      final messages = <String>[];
      for (final value in rawErrors.values) {
        if (value is List) {
          messages.addAll(
            value
                .map((item) => item.toString())
                .where((item) => item.trim().isNotEmpty),
          );
        } else if (value is String && value.trim().isNotEmpty) {
          messages.add(value.trim());
        }
      }
      if (messages.isNotEmpty) return messages.join('\n');
    }

    final message = envelope['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    return fallback;
  }

  Future<String> _getToken() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.trim().isEmpty) {
      throw const DashboardServiceException(
        message: 'Sesi login tidak ditemukan. Silakan login kembali.',
        resourceLabel: 'autentikasi',
      );
    }
    return token.trim();
  }

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num && value.isFinite) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Menutup ApiClient hanya jika service yang membuat instance tersebut.
  void dispose() {
    if (_ownsApiClient) _apiClient.dispose();
  }
}

class _PaginatedPage {
  final List<dynamic> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const _PaginatedPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });
}

class _AllPagesResult<T> {
  final List<T> items;
  final int total;

  const _AllPagesResult({required this.items, required this.total});
}

class DashboardServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String resourceLabel;

  const DashboardServiceException({
    required this.message,
    required this.resourceLabel,
    this.statusCode,
  });

  @override
  String toString() => message;
}
