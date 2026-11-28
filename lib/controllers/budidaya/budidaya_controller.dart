import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/budidaya/budidaya_model.dart';
import '../../services/budidaya/budidaya_service.dart';

/// Controller untuk daftar, detail, tambah, ubah, dan hapus data budidaya.
///
/// Controller hanya mengelola state dan memanggil BudidayaService.
/// Validasi serta penyimpanan data tetap mengikuti aturan backend SIPENTAR.
class BudidayaController extends ChangeNotifier {
  final BudidayaService _budidayaService;

  BudidayaController({BudidayaService? budidayaService})
    : _budidayaService = budidayaService ?? BudidayaService();

  // ---------------------------------------------------------------------------
  // State daftar dan pagination
  // ---------------------------------------------------------------------------

  List<BudidayaModel> _budidayas = [];
  List<BudidayaModel> get budidayas => List.unmodifiable(_budidayas);

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

  int _totalBudidayas = 0;
  int get totalBudidayas => _totalBudidayas;

  bool get hasMoreBudidayas => _currentPage < _lastPage;

  // Filter aktif. Filter yang sama digunakan untuk permintaan halaman berikutnya.
  int? _filterMejaId;
  int? get filterMejaId => _filterMejaId;

  String? _filterStatus;
  String? get filterStatus => _filterStatus;

  DateTime? _filterFrom;
  DateTime? get filterFrom => _filterFrom;

  DateTime? _filterTo;
  DateTime? get filterTo => _filterTo;

  // ---------------------------------------------------------------------------
  // State detail
  // ---------------------------------------------------------------------------

  BudidayaModel? _selectedBudidaya;
  BudidayaModel? get selectedBudidaya => _selectedBudidaya;

  bool _isDetailLoading = false;
  bool get isDetailLoading => _isDetailLoading;

  String? _detailErrorMessage;
  String? get detailErrorMessage => _detailErrorMessage;

  // ---------------------------------------------------------------------------
  // State tambah / ubah / hapus
  // ---------------------------------------------------------------------------

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _submitErrorMessage;
  String? get submitErrorMessage => _submitErrorMessage;

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  int? _deletingBudidayaId;
  int? get deletingBudidayaId => _deletingBudidayaId;

  String? _deleteErrorMessage;
  String? get deleteErrorMessage => _deleteErrorMessage;

  bool _isDisposed = false;

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Daftar budidaya
  // ---------------------------------------------------------------------------

  /// Memuat halaman pertama daftar budidaya dengan filter opsional.
  /// Kirim null pada filter untuk menghapus filter terkait.
  Future<bool> loadBudidayas({
    int? mejaId,
    String? status,
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

    _filterMejaId = mejaId;
    _filterStatus = status;
    _filterFrom = from;
    _filterTo = to;
    _perPage = perPage;

    _isLoading = true;
    _errorMessage = null;
    _loadMoreErrorMessage = null;
    _notify();

    try {
      final result = await _budidayaService.getBudidayasPage(
        page: 1,
        perPage: _perPage,
        mejaId: _filterMejaId,
        status: _filterStatus,
        from: _filterFrom,
        to: _filterTo,
      );

      _budidayas = result.budidayas;
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _perPage = result.perPage;
      _totalBudidayas = result.total;
      _errorMessage = null;
      return true;
    } on BudidayaServiceException catch (e) {
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
      _errorMessage = e.message?.toString() ?? 'Filter budidaya tidak valid.';
      return false;
    } catch (_) {
      _errorMessage = 'Gagal mengambil daftar budidaya. Silakan coba lagi.';
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Memuat ulang daftar dengan filter yang sedang aktif.
  Future<bool> refreshBudidayas() {
    return loadBudidayas(
      mejaId: _filterMejaId,
      status: _filterStatus,
      from: _filterFrom,
      to: _filterTo,
      perPage: _perPage,
    );
  }

  /// Mengambil halaman berikutnya dan menghindari item duplikat.
  Future<bool> loadMoreBudidayas() async {
    if (_isLoading || _isLoadingMore || !hasMoreBudidayas) return false;

    _isLoadingMore = true;
    _loadMoreErrorMessage = null;
    _notify();

    try {
      final result = await _budidayaService.getBudidayasPage(
        page: _currentPage + 1,
        perPage: _perPage,
        mejaId: _filterMejaId,
        status: _filterStatus,
        from: _filterFrom,
        to: _filterTo,
      );

      final existingIds = _budidayas.map((item) => item.id).toSet();
      final newItems = result.budidayas.where(
        (item) => !existingIds.contains(item.id),
      );

      _budidayas = [..._budidayas, ...newItems];
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _perPage = result.perPage;
      _totalBudidayas = result.total;
      _loadMoreErrorMessage = null;
      return true;
    } on BudidayaServiceException catch (e) {
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
      _loadMoreErrorMessage = 'Gagal memuat halaman budidaya berikutnya.';
      return false;
    } finally {
      _isLoadingMore = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Detail budidaya
  // ---------------------------------------------------------------------------

  Future<bool> loadBudidayaDetail({required int id}) async {
    if (_isDetailLoading) return false;

    _isDetailLoading = true;
    _selectedBudidaya = null;
    _detailErrorMessage = null;
    _notify();

    try {
      _selectedBudidaya = await _budidayaService.getBudidayaById(id: id);
      _detailErrorMessage = null;
      return true;
    } on BudidayaServiceException catch (e) {
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
      _detailErrorMessage = e.message?.toString() ?? 'ID budidaya tidak valid.';
      return false;
    } catch (_) {
      _detailErrorMessage = 'Gagal mengambil detail budidaya.';
      return false;
    } finally {
      _isDetailLoading = false;
      _notify();
    }
  }

  void clearSelectedBudidaya() {
    _selectedBudidaya = null;
    _detailErrorMessage = null;
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Tambah budidaya
  // ---------------------------------------------------------------------------

  Future<bool> createBudidaya({
    required int mejaId,
    required DateTime tanggalSemai,
    required int jumlahTanaman,
    String status = BudidayaModel.statusBerjalan,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _submitErrorMessage = null;
    _notify();

    try {
      final created = await _budidayaService.createBudidaya(
        mejaId: mejaId,
        tanggalSemai: tanggalSemai,
        jumlahTanaman: jumlahTanaman,
        status: status,
      );

      _selectedBudidaya = created;
      if (_matchesActiveFilters(created)) {
        _totalBudidayas++;
        if (_currentPage == 1) {
          _budidayas = [
            created,
            ..._budidayas.where((item) => item.id != created.id),
          ];
          if (_budidayas.length > _perPage) {
            _budidayas = _budidayas.take(_perPage).toList();
          }
        }
      }

      _submitErrorMessage = null;
      return true;
    } on BudidayaServiceException catch (e) {
      _submitErrorMessage = e.message;
      return false;
    } on TimeoutException {
      _submitErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return false;
    } on SocketException {
      _submitErrorMessage = 'Server tidak dapat dijangkau. Periksa koneksi internet.';
      return false;
    } on http.ClientException {
      _submitErrorMessage = 'Tidak dapat terhubung ke server. Periksa jaringan.';
      return false;
    } on FormatException catch (e) {
      _submitErrorMessage = e.message;
      return false;
    } on ArgumentError catch (e) {
      _submitErrorMessage = e.message?.toString() ?? 'Data budidaya tidak valid.';
      return false;
    } catch (_) {
      _submitErrorMessage = 'Gagal menambahkan data budidaya.';
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Ubah budidaya
  // ---------------------------------------------------------------------------

  Future<bool> updateBudidaya({
    required int id,
    required int mejaId,
    required DateTime tanggalSemai,
    required int jumlahTanaman,
    required String status,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _submitErrorMessage = null;
    _notify();

    try {
      final updated = await _budidayaService.updateBudidaya(
        id: id,
        mejaId: mejaId,
        tanggalSemai: tanggalSemai,
        jumlahTanaman: jumlahTanaman,
        status: status,
      );

      final previousSelected = _selectedBudidaya?.id == id
          ? _selectedBudidaya
          : null;
      final existingIndex = _budidayas.indexWhere((item) => item.id == id);
      final previousItem = existingIndex >= 0
          ? _budidayas[existingIndex]
          : previousSelected;
      final previouslyMatched = previousItem == null
          ? null
          : _matchesActiveFilters(previousItem);
      final matchesFilters = _matchesActiveFilters(updated);

      _selectedBudidaya = updated;

      if (existingIndex >= 0 && matchesFilters) {
        final copy = List<BudidayaModel>.from(_budidayas);
        copy[existingIndex] = updated;
        _budidayas = copy;
      } else if (existingIndex >= 0 && !matchesFilters) {
        _budidayas = _budidayas.where((item) => item.id != id).toList();
        _decrementTotalBudidayas();
      } else if (previouslyMatched == true && !matchesFilters) {
        _decrementTotalBudidayas();
      } else if (previouslyMatched == false && matchesFilters) {
        _totalBudidayas++;
        if (_currentPage == 1) {
          _budidayas = [updated, ..._budidayas];
          if (_budidayas.length > _perPage) {
            _budidayas = _budidayas.take(_perPage).toList();
          }
        }
      }

      _submitErrorMessage = null;
      return true;
    } on BudidayaServiceException catch (e) {
      _submitErrorMessage = e.message;
      return false;
    } on TimeoutException {
      _submitErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return false;
    } on SocketException {
      _submitErrorMessage = 'Server tidak dapat dijangkau. Periksa koneksi internet.';
      return false;
    } on http.ClientException {
      _submitErrorMessage = 'Tidak dapat terhubung ke server. Periksa jaringan.';
      return false;
    } on FormatException catch (e) {
      _submitErrorMessage = e.message;
      return false;
    } on ArgumentError catch (e) {
      _submitErrorMessage = e.message?.toString() ?? 'Data budidaya tidak valid.';
      return false;
    } catch (_) {
      _submitErrorMessage = 'Gagal memperbarui data budidaya.';
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Hapus budidaya
  // ---------------------------------------------------------------------------

  Future<bool> deleteBudidaya({required int id}) async {
    if (_isDeleting) return false;

    _isDeleting = true;
    _deletingBudidayaId = id;
    _deleteErrorMessage = null;
    _notify();

    try {
      await _budidayaService.deleteBudidaya(id: id);

      final oldLength = _budidayas.length;
      _budidayas = _budidayas.where((item) => item.id != id).toList();
      if (_budidayas.length != oldLength) {
        _decrementTotalBudidayas();
      }

      if (_selectedBudidaya?.id == id) {
        _selectedBudidaya = null;
      }

      _deleteErrorMessage = null;
      return true;
    } on BudidayaServiceException catch (e) {
      _deleteErrorMessage = e.message;
      return false;
    } on TimeoutException {
      _deleteErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return false;
    } on SocketException {
      _deleteErrorMessage = 'Server tidak dapat dijangkau. Periksa koneksi internet.';
      return false;
    } on http.ClientException {
      _deleteErrorMessage = 'Tidak dapat terhubung ke server. Periksa jaringan.';
      return false;
    } on FormatException catch (e) {
      _deleteErrorMessage = e.message;
      return false;
    } on ArgumentError catch (e) {
      _deleteErrorMessage = e.message?.toString() ?? 'ID budidaya tidak valid.';
      return false;
    } catch (_) {
      _deleteErrorMessage = 'Gagal menghapus data budidaya.';
      return false;
    } finally {
      _isDeleting = false;
      _deletingBudidayaId = null;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Utility state
  // ---------------------------------------------------------------------------

  void _decrementTotalBudidayas() {
    if (_totalBudidayas > 0) {
      _totalBudidayas--;
    }
  }

  bool _matchesActiveFilters(BudidayaModel item) {
    if (_filterMejaId != null && item.mejaId != _filterMejaId) return false;
    if (_filterStatus != null && item.status != _filterStatus) return false;

    final itemDate = _dateOnly(item.tanggalSemai);
    if (_filterFrom != null && itemDate.isBefore(_dateOnly(_filterFrom!))) {
      return false;
    }
    if (_filterTo != null && itemDate.isAfter(_dateOnly(_filterTo!))) {
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

  void clearSubmitError() {
    _submitErrorMessage = null;
    _notify();
  }

  void clearDeleteError() {
    _deleteErrorMessage = null;
    _notify();
  }

  /// Mengatur ulang daftar, filter, detail, dan pesan error.
  void reset() {
    if (_isLoading || _isLoadingMore || _isDetailLoading || _isSubmitting || _isDeleting) {
      return;
    }

    _budidayas = [];
    _currentPage = 1;
    _lastPage = 1;
    _perPage = 15;
    _totalBudidayas = 0;
    _filterMejaId = null;
    _filterStatus = null;
    _filterFrom = null;
    _filterTo = null;
    _selectedBudidaya = null;
    _errorMessage = null;
    _loadMoreErrorMessage = null;
    _detailErrorMessage = null;
    _submitErrorMessage = null;
    _deleteErrorMessage = null;
    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _budidayaService.dispose();
    super.dispose();
  }
}
