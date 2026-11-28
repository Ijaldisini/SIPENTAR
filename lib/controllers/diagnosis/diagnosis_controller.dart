import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/diagnosis/diagnosis_model.dart';
import '../../services/diagnosis/diagnosis_service.dart';

/// Controller untuk daftar, detail, dan proses upload diagnosis kesehatan.
///
/// Controller hanya mengelola state dan memanggil DiagnosisService.
/// Klasifikasi gambar, penyimpanan, dan rekomendasi tetap berasal dari backend.
class DiagnosisController extends ChangeNotifier {
  final DiagnosisService _diagnosisService;

  DiagnosisController({DiagnosisService? diagnosisService})
    : _diagnosisService = diagnosisService ?? DiagnosisService();

  // ---------------------------------------------------------------------------
  // State daftar dan pagination
  // ---------------------------------------------------------------------------

  List<DiagnosisModel> _diagnoses = [];
  List<DiagnosisModel> get diagnoses => List.unmodifiable(_diagnoses);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _loadMoreErrorMessage;
  String? get loadMoreErrorMessage => _loadMoreErrorMessage;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _lastPage = 1;
  int get lastPage => _lastPage;

  int _perPage = 15;
  int get perPage => _perPage;

  int _totalDiagnoses = 0;
  int get totalDiagnoses => _totalDiagnoses;

  bool get hasMoreDiagnoses => _currentPage < _lastPage;

  // Filter aktif, digunakan kembali ketika memuat halaman berikutnya.
  int? _filterBudidayaId;
  int? get filterBudidayaId => _filterBudidayaId;

  String? _filterHasil;
  String? get filterHasil => _filterHasil;

  DateTime? _filterFrom;
  DateTime? get filterFrom => _filterFrom;

  DateTime? _filterTo;
  DateTime? get filterTo => _filterTo;

  // ---------------------------------------------------------------------------
  // State detail
  // ---------------------------------------------------------------------------

  DiagnosisModel? _selectedDiagnosis;
  DiagnosisModel? get selectedDiagnosis => _selectedDiagnosis;

  bool _isDetailLoading = false;
  bool get isDetailLoading => _isDetailLoading;

  String? _detailErrorMessage;
  String? get detailErrorMessage => _detailErrorMessage;

  // ---------------------------------------------------------------------------
  // State upload diagnosis
  // ---------------------------------------------------------------------------

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _submitErrorMessage;
  String? get submitErrorMessage => _submitErrorMessage;

  DiagnosisModel? _latestDiagnosis;
  DiagnosisModel? get latestDiagnosis => _latestDiagnosis;

  bool _isDisposed = false;

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Daftar diagnosis
  // ---------------------------------------------------------------------------

  /// Memuat halaman pertama daftar diagnosis dengan filter opsional.
  /// Kirim null pada filter untuk menghapus filter terkait.
  Future<bool> loadDiagnoses({
    int? budidayaId,
    String? hasil,
    DateTime? from,
    DateTime? to,
    int perPage = 15,
  }) async {
    if (_isLoading || _isLoadingMore) return false;

    if (from != null &&
        to != null &&
        _dateOnly(from).isAfter(_dateOnly(to))) {
      _errorMessage = 'Tanggal awal tidak boleh melewati tanggal akhir.';
      _notify();
      return false;
    }

    _filterBudidayaId = budidayaId;
    _filterHasil = hasil;
    _filterFrom = from;
    _filterTo = to;
    _perPage = perPage;

    _isLoading = true;
    _errorMessage = null;
    _loadMoreErrorMessage = null;
    _notify();

    try {
      final result = await _diagnosisService.getDiagnosesPage(
        page: 1,
        perPage: _perPage,
        budidayaId: _filterBudidayaId,
        hasil: _filterHasil,
        from: _filterFrom,
        to: _filterTo,
      );

      _diagnoses = result.diagnoses;
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _perPage = result.perPage;
      _totalDiagnoses = result.total;
      _errorMessage = null;
      return true;
    } on DiagnosisServiceException catch (e) {
      _errorMessage = e.message;
      return false;
    } on TimeoutException {
      _errorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return false;
    } on SocketException {
      _errorMessage = 'Server tidak dapat dijangkau. Periksa koneksi internet.';
      return false;
    } on http.ClientException {
      _errorMessage = 'Tidak dapat terhubung ke server. Periksa jaringan.';
      return false;
    } on FormatException catch (e) {
      _errorMessage = e.message;
      return false;
    } on ArgumentError catch (e) {
      _errorMessage = e.message?.toString() ?? 'Filter diagnosis tidak valid.';
      return false;
    } catch (_) {
      _errorMessage = 'Gagal mengambil daftar diagnosis. Silakan coba lagi.';
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Memuat ulang daftar dengan filter yang sedang aktif.
  Future<bool> refreshDiagnoses() {
    return loadDiagnoses(
      budidayaId: _filterBudidayaId,
      hasil: _filterHasil,
      from: _filterFrom,
      to: _filterTo,
      perPage: _perPage,
    );
  }

  /// Mengambil halaman berikutnya dan menghindari item duplikat.
  Future<bool> loadMoreDiagnoses() async {
    if (_isLoading || _isLoadingMore || !hasMoreDiagnoses) return false;

    _isLoadingMore = true;
    _loadMoreErrorMessage = null;
    _notify();

    try {
      final result = await _diagnosisService.getDiagnosesPage(
        page: _currentPage + 1,
        perPage: _perPage,
        budidayaId: _filterBudidayaId,
        hasil: _filterHasil,
        from: _filterFrom,
        to: _filterTo,
      );

      final existingIds = _diagnoses.map((item) => item.id).toSet();
      final newItems = result.diagnoses.where(
        (item) => !existingIds.contains(item.id),
      );

      _diagnoses = [..._diagnoses, ...newItems];
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _perPage = result.perPage;
      _totalDiagnoses = result.total;
      _loadMoreErrorMessage = null;
      return true;
    } on DiagnosisServiceException catch (e) {
      _loadMoreErrorMessage = e.message;
      return false;
    } on TimeoutException {
      _loadMoreErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return false;
    } on SocketException {
      _loadMoreErrorMessage = 'Server tidak dapat dijangkau. Periksa koneksi internet.';
      return false;
    } on http.ClientException {
      _loadMoreErrorMessage = 'Tidak dapat terhubung ke server. Periksa jaringan.';
      return false;
    } on FormatException catch (e) {
      _loadMoreErrorMessage = e.message;
      return false;
    } catch (_) {
      _loadMoreErrorMessage = 'Gagal memuat riwayat diagnosis berikutnya.';
      return false;
    } finally {
      _isLoadingMore = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Detail diagnosis
  // ---------------------------------------------------------------------------

  Future<bool> loadDiagnosisDetail({required int id}) async {
    if (_isDetailLoading) return false;

    _isDetailLoading = true;
    _selectedDiagnosis = null;
    _detailErrorMessage = null;
    _notify();

    try {
      _selectedDiagnosis = await _diagnosisService.getDiagnosisById(id: id);
      _detailErrorMessage = null;
      return true;
    } on DiagnosisServiceException catch (e) {
      _detailErrorMessage = e.message;
      return false;
    } on TimeoutException {
      _detailErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return false;
    } on SocketException {
      _detailErrorMessage = 'Server tidak dapat dijangkau. Periksa koneksi internet.';
      return false;
    } on http.ClientException {
      _detailErrorMessage = 'Tidak dapat terhubung ke server. Periksa jaringan.';
      return false;
    } on FormatException catch (e) {
      _detailErrorMessage = e.message;
      return false;
    } on ArgumentError catch (e) {
      _detailErrorMessage = e.message?.toString() ?? 'ID diagnosis tidak valid.';
      return false;
    } catch (_) {
      _detailErrorMessage = 'Gagal mengambil detail diagnosis. Silakan coba lagi.';
      return false;
    } finally {
      _isDetailLoading = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Upload diagnosis
  // ---------------------------------------------------------------------------

  /// Mengirim satu gambar dan ID budidaya ke endpoint POST /diagnosis.
  /// Mengembalikan data diagnosis saat berhasil, atau null jika gagal.
  Future<DiagnosisModel?> createDiagnosis({
    required File image,
    required int budidayaId,
  }) async {
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _submitErrorMessage = null;
    _notify();

    try {
      final diagnosis = await _diagnosisService.createDiagnosis(
        image: image,
        budidayaId: budidayaId,
      );

      _latestDiagnosis = diagnosis;
      _selectedDiagnosis = diagnosis;
      _submitErrorMessage = null;

      // Response create berisi data lengkap. Perbarui daftar lokal jika hasil
      // sesuai filter yang sedang aktif, agar layar tidak perlu menebak data.
      if (_matchesActiveFilters(diagnosis)) {
        _totalDiagnoses++;
        if (_currentPage <= 1) {
          _diagnoses = [
            diagnosis,
            ..._diagnoses.where((item) => item.id != diagnosis.id),
          ];
          if (_diagnoses.length > _perPage) {
            _diagnoses = _diagnoses.take(_perPage).toList();
          }
        }
      }

      return diagnosis;
    } on DiagnosisServiceException catch (e) {
      _submitErrorMessage = e.message;
      return null;
    } on TimeoutException {
      _submitErrorMessage = 'Upload foto melewati batas waktu. Silakan coba lagi.';
      return null;
    } on SocketException {
      _submitErrorMessage = 'Server tidak dapat dijangkau. Periksa koneksi internet.';
      return null;
    } on http.ClientException {
      _submitErrorMessage = 'Upload foto gagal karena koneksi ke server terputus.';
      return null;
    } on FormatException catch (e) {
      _submitErrorMessage = e.message;
      return null;
    } on ArgumentError catch (e) {
      _submitErrorMessage = e.message?.toString() ?? 'Data diagnosis tidak valid.';
      return null;
    } catch (_) {
      _submitErrorMessage = 'Gagal mengirim foto untuk diagnosis. Silakan coba lagi.';
      return null;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers dan reset state
  // ---------------------------------------------------------------------------

  bool _matchesActiveFilters(DiagnosisModel item) {
    if (_filterBudidayaId != null && item.budidayaId != _filterBudidayaId) {
      return false;
    }

    if (_filterHasil != null && item.hasil != _filterHasil) {
      return false;
    }

    final diagnosisDate = _dateOnly(item.tanggalDiagnosis);
    if (_filterFrom != null &&
        diagnosisDate.isBefore(_dateOnly(_filterFrom!))) {
      return false;
    }
    if (_filterTo != null && diagnosisDate.isAfter(_dateOnly(_filterTo!))) {
      return false;
    }

    return true;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  void clearError() {
    _errorMessage = null;
    _notify();
  }

  void clearLoadMoreError() {
    _loadMoreErrorMessage = null;
    _notify();
  }

  void clearDetailError() {
    _detailErrorMessage = null;
    _notify();
  }

  void clearSubmitError() {
    _submitErrorMessage = null;
    _notify();
  }

  void clearSelectedDiagnosis() {
    _selectedDiagnosis = null;
    _detailErrorMessage = null;
    _notify();
  }

  /// Mengatur ulang daftar, filter, detail, dan pesan error.
  void reset() {
    if (_isLoading || _isLoadingMore || _isDetailLoading || _isSubmitting) {
      return;
    }

    _diagnoses = [];
    _currentPage = 1;
    _lastPage = 1;
    _perPage = 15;
    _totalDiagnoses = 0;
    _filterBudidayaId = null;
    _filterHasil = null;
    _filterFrom = null;
    _filterTo = null;
    _selectedDiagnosis = null;
    _latestDiagnosis = null;
    _errorMessage = null;
    _loadMoreErrorMessage = null;
    _detailErrorMessage = null;
    _submitErrorMessage = null;
    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _diagnosisService.dispose();
    super.dispose();
  }
}
