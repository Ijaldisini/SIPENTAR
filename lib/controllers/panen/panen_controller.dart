import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/panen/panen_model.dart';
import '../../services/panen/panen_service.dart';

/// Controller untuk daftar, detail, tambah, ubah, dan hapus data panen.
///
/// Controller hanya mengelola state dan memanggil PanenService.
/// Validasi utama dan aturan bisnis tetap mengikuti backend SIPENTAR.
class PanenController extends ChangeNotifier {
  final PanenService _panenService;

  PanenController({PanenService? panenService})
    : _panenService = panenService ?? PanenService();

  // ---------------------------------------------------------------------------
  // State daftar dan pagination
  // ---------------------------------------------------------------------------

  List<PanenModel> _panens = [];
  List<PanenModel> get panens => List.unmodifiable(_panens);

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

  int _totalPanens = 0;
  int get totalPanens => _totalPanens;

  bool get hasMorePanens => _currentPage < _lastPage;

  // Filter aktif. Filter yang sama digunakan untuk halaman berikutnya.
  int? _filterBudidayaId;
  int? get filterBudidayaId => _filterBudidayaId;

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

  PanenModel? _selectedPanen;
  PanenModel? get selectedPanen => _selectedPanen;

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

  int? _deletingPanenId;
  int? get deletingPanenId => _deletingPanenId;

  String? _deleteErrorMessage;
  String? get deleteErrorMessage => _deleteErrorMessage;

  bool _isDisposed = false;

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Daftar panen
  // ---------------------------------------------------------------------------

  /// Memuat halaman pertama daftar panen dengan filter opsional.
  /// Kirim null pada filter untuk menghapus filter terkait.
  Future<bool> loadPanens({
    int? budidayaId,
    int? mejaId,
    String? status,
    DateTime? from,
    DateTime? to,
    int perPage = 15,
  }) async {
    if (_isLoading || _isLoadingMore) return false;

    if (from != null && to != null && _dateOnly(from).isAfter(_dateOnly(to))) {
      _errorMessage = 'Tanggal awal tidak boleh melewati tanggal akhir.';
      _notify();
      return false;
    }

    _filterBudidayaId = budidayaId;
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
      final result = await _panenService.getPanensPage(
        page: 1,
        perPage: _perPage,
        budidayaId: _filterBudidayaId,
        mejaId: _filterMejaId,
        status: _filterStatus,
        from: _filterFrom,
        to: _filterTo,
      );

      _panens = result.panens;
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _perPage = result.perPage;
      _totalPanens = result.total;
      _errorMessage = null;
      return true;
    } on PanenServiceException catch (e) {
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
      _errorMessage = e.message?.toString() ?? 'Filter panen tidak valid.';
      return false;
    } catch (_) {
      _errorMessage = 'Gagal mengambil daftar panen. Silakan coba lagi.';
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Memuat ulang daftar menggunakan filter yang sedang aktif.
  Future<bool> refreshPanens() {
    return loadPanens(
      budidayaId: _filterBudidayaId,
      mejaId: _filterMejaId,
      status: _filterStatus,
      from: _filterFrom,
      to: _filterTo,
      perPage: _perPage,
    );
  }

  /// Mengambil halaman berikutnya dan menghindari item duplikat.
  Future<bool> loadMorePanens() async {
    if (_isLoading || _isLoadingMore || !hasMorePanens) return false;

    _isLoadingMore = true;
    _loadMoreErrorMessage = null;
    _notify();

    try {
      final result = await _panenService.getPanensPage(
        page: _currentPage + 1,
        perPage: _perPage,
        budidayaId: _filterBudidayaId,
        mejaId: _filterMejaId,
        status: _filterStatus,
        from: _filterFrom,
        to: _filterTo,
      );

      final existingIds = _panens.map((item) => item.id).toSet();
      final newItems = result.panens.where(
        (item) => !existingIds.contains(item.id),
      );

      _panens = [..._panens, ...newItems];
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _perPage = result.perPage;
      _totalPanens = result.total;
      _loadMoreErrorMessage = null;
      return true;
    } on PanenServiceException catch (e) {
      _loadMoreErrorMessage = e.message;
      return false;
    } on TimeoutException {
      _loadMoreErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return false;
    } on SocketException {
      _loadMoreErrorMessage =
          'Server tidak dapat dijangkau. Periksa koneksi internet.';
      return false;
    } on http.ClientException {
      _loadMoreErrorMessage =
          'Tidak dapat terhubung ke server. Periksa jaringan.';
      return false;
    } on FormatException catch (e) {
      _loadMoreErrorMessage = e.message;
      return false;
    } catch (_) {
      _loadMoreErrorMessage = 'Gagal memuat halaman panen berikutnya.';
      return false;
    } finally {
      _isLoadingMore = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Detail panen
  // ---------------------------------------------------------------------------

  Future<bool> loadPanenDetail({required int id}) async {
    if (_isDetailLoading) return false;

    _isDetailLoading = true;
    _selectedPanen = null;
    _detailErrorMessage = null;
    _notify();

    try {
      _selectedPanen = await _panenService.getPanenById(id: id);
      _detailErrorMessage = null;
      return true;
    } on PanenServiceException catch (e) {
      _detailErrorMessage = e.message;
      return false;
    } on TimeoutException {
      _detailErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return false;
    } on SocketException {
      _detailErrorMessage =
          'Server tidak dapat dijangkau. Periksa koneksi internet.';
      return false;
    } on http.ClientException {
      _detailErrorMessage =
          'Tidak dapat terhubung ke server. Periksa jaringan.';
      return false;
    } on FormatException catch (e) {
      _detailErrorMessage = e.message;
      return false;
    } on ArgumentError catch (e) {
      _detailErrorMessage = e.message?.toString() ?? 'ID panen tidak valid.';
      return false;
    } catch (_) {
      _detailErrorMessage = 'Gagal mengambil detail panen.';
      return false;
    } finally {
      _isDetailLoading = false;
      _notify();
    }
  }

  void clearSelectedPanen() {
    _selectedPanen = null;
    _detailErrorMessage = null;
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Tambah panen
  // ---------------------------------------------------------------------------

  Future<bool> createPanen({
    required int budidayaId,
    required DateTime tanggalPanen,
    required String status,
    double? beratKg,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _submitErrorMessage = null;
    _notify();

    try {
      final created = await _panenService.createPanen(
        budidayaId: budidayaId,
        tanggalPanen: tanggalPanen,
        status: status,
        beratKg: beratKg,
      );

      _selectedPanen = created;
      if (_matchesActiveFilters(created)) {
        _totalPanens++;
        if (_currentPage == 1) {
          _panens = [
            created,
            ..._panens.where((item) => item.id != created.id),
          ];
          if (_panens.length > _perPage) {
            _panens = _panens.take(_perPage).toList();
          }
        }
      }

      _submitErrorMessage = null;
      return true;
    } on PanenServiceException catch (e) {
      _submitErrorMessage = e.message;
      return false;
    } on TimeoutException {
      _submitErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return false;
    } on SocketException {
      _submitErrorMessage =
          'Server tidak dapat dijangkau. Periksa koneksi internet.';
      return false;
    } on http.ClientException {
      _submitErrorMessage =
          'Tidak dapat terhubung ke server. Periksa jaringan.';
      return false;
    } on FormatException catch (e) {
      _submitErrorMessage = e.message;
      return false;
    } on ArgumentError catch (e) {
      _submitErrorMessage = e.message?.toString() ?? 'Data panen tidak valid.';
      return false;
    } catch (_) {
      _submitErrorMessage = 'Gagal menambahkan data panen.';
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Ubah panen
  // ---------------------------------------------------------------------------

  Future<bool> updatePanen({
    required int id,
    required int budidayaId,
    required DateTime tanggalPanen,
    required String status,
    double? beratKg,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _submitErrorMessage = null;
    _notify();

    try {
      final updated = await _panenService.updatePanen(
        id: id,
        budidayaId: budidayaId,
        tanggalPanen: tanggalPanen,
        status: status,
        beratKg: beratKg,
      );

      final previousSelected = _selectedPanen?.id == id ? _selectedPanen : null;
      final existingIndex = _panens.indexWhere((item) => item.id == id);
      final previousItem = existingIndex >= 0
          ? _panens[existingIndex]
          : previousSelected;
      final previouslyMatched = previousItem == null
          ? null
          : _matchesActiveFilters(previousItem);
      final matchesFilters = _matchesActiveFilters(updated);

      _selectedPanen = updated;

      if (existingIndex >= 0 && matchesFilters) {
        final copy = List<PanenModel>.from(_panens);
        copy[existingIndex] = updated;
        _panens = copy;
      } else if (existingIndex >= 0 && !matchesFilters) {
        _panens = _panens.where((item) => item.id != id).toList();
        _decrementTotalPanens();
      } else if (previouslyMatched == true && !matchesFilters) {
        _decrementTotalPanens();
      } else if (previouslyMatched == false && matchesFilters) {
        _totalPanens++;
        if (_currentPage == 1) {
          _panens = [updated, ..._panens];
          if (_panens.length > _perPage) {
            _panens = _panens.take(_perPage).toList();
          }
        }
      }

      _submitErrorMessage = null;
      return true;
    } on PanenServiceException catch (e) {
      _submitErrorMessage = e.message;
      return false;
    } on TimeoutException {
      _submitErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return false;
    } on SocketException {
      _submitErrorMessage =
          'Server tidak dapat dijangkau. Periksa koneksi internet.';
      return false;
    } on http.ClientException {
      _submitErrorMessage =
          'Tidak dapat terhubung ke server. Periksa jaringan.';
      return false;
    } on FormatException catch (e) {
      _submitErrorMessage = e.message;
      return false;
    } on ArgumentError catch (e) {
      _submitErrorMessage = e.message?.toString() ?? 'Data panen tidak valid.';
      return false;
    } catch (_) {
      _submitErrorMessage = 'Gagal memperbarui data panen.';
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Hapus panen
  // ---------------------------------------------------------------------------

  Future<bool> deletePanen({required int id}) async {
    if (_isDeleting) return false;

    _isDeleting = true;
    _deletingPanenId = id;
    _deleteErrorMessage = null;
    _notify();

    try {
      await _panenService.deletePanen(id: id);

      final oldLength = _panens.length;
      _panens = _panens.where((item) => item.id != id).toList();
      if (_panens.length != oldLength) {
        _decrementTotalPanens();
      }

      if (_selectedPanen?.id == id) {
        _selectedPanen = null;
      }

      _deleteErrorMessage = null;
      return true;
    } on PanenServiceException catch (e) {
      _deleteErrorMessage = e.message;
      return false;
    } on TimeoutException {
      _deleteErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return false;
    } on SocketException {
      _deleteErrorMessage =
          'Server tidak dapat dijangkau. Periksa koneksi internet.';
      return false;
    } on http.ClientException {
      _deleteErrorMessage =
          'Tidak dapat terhubung ke server. Periksa jaringan.';
      return false;
    } on FormatException catch (e) {
      _deleteErrorMessage = e.message;
      return false;
    } on ArgumentError catch (e) {
      _deleteErrorMessage = e.message?.toString() ?? 'ID panen tidak valid.';
      return false;
    } catch (_) {
      _deleteErrorMessage = 'Gagal menghapus data panen.';
      return false;
    } finally {
      _isDeleting = false;
      _deletingPanenId = null;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Utility state dan filter
  // ---------------------------------------------------------------------------

  void _decrementTotalPanens() {
    if (_totalPanens > 0) {
      _totalPanens--;
    }
  }

  bool _matchesActiveFilters(PanenModel item) {
    if (_filterBudidayaId != null && item.budidayaId != _filterBudidayaId) {
      return false;
    }

    if (_filterMejaId != null && item.budidaya?.mejaId != _filterMejaId) {
      return false;
    }

    if (_filterStatus != null && item.status != _filterStatus) {
      return false;
    }

    final itemDate = _dateOnly(item.tanggalPanen);
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
    if (_isLoading ||
        _isLoadingMore ||
        _isDetailLoading ||
        _isSubmitting ||
        _isDeleting) {
      return;
    }

    _panens = [];
    _currentPage = 1;
    _lastPage = 1;
    _perPage = 15;
    _totalPanens = 0;
    _filterBudidayaId = null;
    _filterMejaId = null;
    _filterStatus = null;
    _filterFrom = null;
    _filterTo = null;
    _selectedPanen = null;
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
    _panenService.dispose();
    super.dispose();
  }
}
