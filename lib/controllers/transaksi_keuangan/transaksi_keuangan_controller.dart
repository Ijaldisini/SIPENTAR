import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/transaksi_keuangan/transaksi_keuangan_model.dart';
import '../../models/transaksi_keuangan/laporan_keuangan_model.dart';
import '../../services/transaksi_keuangan/transaksi_keuangan_service.dart';

/// Controller untuk mengelola daftar, detail, tambah, dan ubah transaksi.
///
/// Endpoint transaksi keuangan pada backend SIPENTAR hanya dapat digunakan
/// oleh pengguna dengan role `pemilik`.
class TransaksiKeuanganController extends ChangeNotifier {
  final TransaksiKeuanganService _transaksiService;

  TransaksiKeuanganController({
    TransaksiKeuanganService? transaksiService,
  }) : _transaksiService =
           transaksiService ?? TransaksiKeuanganService();

  // ---------------------------------------------------------------------------
  // State daftar transaksi
  // ---------------------------------------------------------------------------

  List<TransaksiKeuanganModel> _transactions = [];
  List<TransaksiKeuanganModel> get transactions =>
      List.unmodifiable(_transactions);

  /// Alias berbahasa Indonesia untuk memudahkan pemakaian pada View.
  List<TransaksiKeuanganModel> get transaksiKeuangan => transactions;

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

  int _totalTransactions = 0;
  int get totalTransactions => _totalTransactions;

  bool get hasMoreTransactions => _currentPage < _lastPage;

  // Filter aktif. Filter ini juga dipakai ketika meminta halaman berikutnya.
  String? _filterJenis;
  String? get filterJenis => _filterJenis;

  DateTime? _filterFrom;
  DateTime? get filterFrom => _filterFrom;

  DateTime? _filterTo;
  DateTime? get filterTo => _filterTo;

  // ---------------------------------------------------------------------------
  // State ringkasan laporan keuangan
  // ---------------------------------------------------------------------------

  LaporanKeuanganModel? _laporanKeuangan;
  LaporanKeuanganModel? get laporanKeuangan => _laporanKeuangan;

  bool _isReportLoading = false;
  bool get isReportLoading => _isReportLoading;

  String? _reportErrorMessage;
  String? get reportErrorMessage => _reportErrorMessage;

  // ---------------------------------------------------------------------------
  // State detail dan proses simpan
  // ---------------------------------------------------------------------------

  TransaksiKeuanganModel? _selectedTransaction;
  TransaksiKeuanganModel? get selectedTransaction => _selectedTransaction;

  bool _isDetailLoading = false;
  bool get isDetailLoading => _isDetailLoading;

  String? _detailErrorMessage;
  String? get detailErrorMessage => _detailErrorMessage;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _submitErrorMessage;
  String? get submitErrorMessage => _submitErrorMessage;

  bool _isDisposed = false;

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Ambil daftar transaksi
  // ---------------------------------------------------------------------------

  /// Memuat halaman pertama transaksi dengan filter opsional.
  ///
  /// Memanggil method ini kembali akan mengganti filter yang sedang aktif.
  /// Kirim null untuk menghapus filter terkait.
  Future<bool> loadTransaksiKeuangan({
    String? jenis,
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

    _filterJenis = jenis;
    _filterFrom = from;
    _filterTo = to;
    _perPage = perPage;

    _isLoading = true;
    _errorMessage = null;
    _loadMoreErrorMessage = null;
    _notify();

    try {
      final result = await _transaksiService.getTransaksiKeuanganPage(
        page: 1,
        perPage: _perPage,
        jenis: _filterJenis,
        from: _filterFrom,
        to: _filterTo,
      );

      _transactions = result.transactions;
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _perPage = result.perPage;
      _totalTransactions = result.total;
      _errorMessage = null;
      return true;
    } on TransaksiKeuanganServiceException catch (e) {
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
      _errorMessage = e.message?.toString() ?? 'Filter transaksi tidak valid.';
      return false;
    } catch (_) {
      _errorMessage = 'Gagal mengambil transaksi keuangan. Silakan coba lagi.';
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Memuat ulang daftar menggunakan filter yang sedang aktif.
  Future<bool> refreshTransaksiKeuangan() {
    return loadTransaksiKeuangan(
      jenis: _filterJenis,
      from: _filterFrom,
      to: _filterTo,
      perPage: _perPage,
    );
  }

  /// Mengambil halaman berikutnya tanpa menghapus data yang sudah dimuat.
  Future<bool> loadMoreTransaksiKeuangan() async {
    if (_isLoading || _isLoadingMore || !hasMoreTransactions) return false;

    _isLoadingMore = true;
    _loadMoreErrorMessage = null;
    _notify();

    try {
      final nextPage = _currentPage + 1;
      final result = await _transaksiService.getTransaksiKeuanganPage(
        page: nextPage,
        perPage: _perPage,
        jenis: _filterJenis,
        from: _filterFrom,
        to: _filterTo,
      );

      final existingIds = _transactions.map((item) => item.id).toSet();
      final newItems = result.transactions.where(
        (item) => !existingIds.contains(item.id),
      );

      _transactions = [..._transactions, ...newItems];
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _totalTransactions = result.total;
      _loadMoreErrorMessage = null;
      return true;
    } on TransaksiKeuanganServiceException catch (e) {
      _loadMoreErrorMessage = e.message;
      return false;
    } on TimeoutException {
      _loadMoreErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return false;
    } on SocketException {
      _loadMoreErrorMessage = 'Server tidak dapat dijangkau. Periksa jaringan.';
      return false;
    } on http.ClientException {
      _loadMoreErrorMessage = 'Tidak dapat terhubung ke server. Periksa jaringan.';
      return false;
    } on FormatException catch (e) {
      _loadMoreErrorMessage = e.message;
      return false;
    } catch (_) {
      _loadMoreErrorMessage = 'Gagal memuat transaksi berikutnya.';
      return false;
    } finally {
      _isLoadingMore = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Ambil ringkasan laporan keuangan
  // ---------------------------------------------------------------------------

  Future<bool> loadLaporanKeuangan({
    required DateTime from,
    required DateTime to,
  }) async {
    if (_isReportLoading) return false;

    _isReportLoading = true;
    _reportErrorMessage = null;
    _notify();

    try {
      _laporanKeuangan = await _transaksiService.getLaporanKeuangan(
        from: from,
        to: to,
      );
      _reportErrorMessage = null;
      return true;
    } on TransaksiKeuanganServiceException catch (e) {
      _reportErrorMessage = e.message;
      return false;
    } on TimeoutException {
      _reportErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return false;
    } on SocketException {
      _reportErrorMessage = 'Server tidak dapat dijangkau. Periksa jaringan.';
      return false;
    } on http.ClientException {
      _reportErrorMessage = 'Tidak dapat terhubung ke server. Periksa jaringan.';
      return false;
    } on FormatException catch (e) {
      _reportErrorMessage = e.message;
      return false;
    } on ArgumentError catch (e) {
      _reportErrorMessage = e.message?.toString() ?? 'Rentang tanggal tidak valid.';
      return false;
    } catch (_) {
      _reportErrorMessage = 'Gagal mengambil ringkasan keuangan.';
      return false;
    } finally {
      _isReportLoading = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Ambil detail transaksi
  // ---------------------------------------------------------------------------

  Future<bool> loadTransaksiKeuanganDetail({required int id}) async {
    if (_isDetailLoading) return false;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    _notify();

    try {
      _selectedTransaction = await _transaksiService
          .getTransaksiKeuanganById(id: id);
      _detailErrorMessage = null;
      return true;
    } on TransaksiKeuanganServiceException catch (e) {
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
      _detailErrorMessage = e.message?.toString() ?? 'ID transaksi tidak valid.';
      return false;
    } catch (_) {
      _detailErrorMessage = 'Gagal mengambil detail transaksi.';
      return false;
    } finally {
      _isDetailLoading = false;
      _notify();
    }
  }

  void clearSelectedTransaction() {
    _selectedTransaction = null;
    _detailErrorMessage = null;
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Tambah transaksi
  // ---------------------------------------------------------------------------

  Future<bool> createTransaksiKeuangan({
    required String jenis,
    required DateTime tanggal,
    required double jumlah,
    int? panenId,
    double? persentaseKas,
    String? keterangan,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _submitErrorMessage = null;
    _notify();

    try {
      final created = await _transaksiService.createTransaksiKeuangan(
        jenis: jenis,
        tanggal: tanggal,
        jumlah: jumlah,
        panenId: panenId,
        persentaseKas: persentaseKas,
        keterangan: keterangan,
      );

      if (_matchesCurrentFilter(created)) {
        _transactions.removeWhere((item) => item.id == created.id);
        if (_currentPage == 1) {
          _transactions.insert(0, created);
          _sortTransactionsByDate();
          if (_transactions.length > _perPage) {
            _transactions.removeLast();
          }
        }
        _totalTransactions++;
      }

      _selectedTransaction = created;
      _submitErrorMessage = null;
      return true;
    } on TransaksiKeuanganServiceException catch (e) {
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
      _submitErrorMessage = e.message?.toString() ?? 'Data transaksi tidak valid.';
      return false;
    } catch (_) {
      _submitErrorMessage = 'Gagal menyimpan transaksi keuangan.';
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Ubah transaksi
  // ---------------------------------------------------------------------------

  Future<bool> updateTransaksiKeuangan({
    required int id,
    required String jenis,
    required DateTime tanggal,
    required double jumlah,
    int? panenId,
    double? persentaseKas,
    String? keterangan,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _submitErrorMessage = null;
    _notify();

    try {
      final updated = await _transaksiService.updateTransaksiKeuangan(
        id: id,
        jenis: jenis,
        tanggal: tanggal,
        jumlah: jumlah,
        panenId: panenId,
        persentaseKas: persentaseKas,
        keterangan: keterangan,
      );

      final previousIndex = _transactions.indexWhere((item) => item.id == id);
      final wasInCurrentList = previousIndex >= 0;
      final shouldBeInCurrentList = _matchesCurrentFilter(updated);

      if (wasInCurrentList && !shouldBeInCurrentList) {
        _transactions.removeAt(previousIndex);
        if (_totalTransactions > 0) _totalTransactions--;
      } else if (!wasInCurrentList && shouldBeInCurrentList) {
        if (_currentPage == 1) {
          _transactions.insert(0, updated);
          if (_transactions.length > _perPage) {
            _transactions.removeLast();
          }
        }
        _totalTransactions++;
      } else if (wasInCurrentList && shouldBeInCurrentList) {
        _transactions[previousIndex] = updated;
        _sortTransactionsByDate();
      }

      _selectedTransaction = updated;
      _submitErrorMessage = null;
      return true;
    } on TransaksiKeuanganServiceException catch (e) {
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
      _submitErrorMessage = e.message?.toString() ?? 'Data transaksi tidak valid.';
      return false;
    } catch (_) {
      _submitErrorMessage = 'Gagal memperbarui transaksi keuangan.';
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  bool _matchesCurrentFilter(TransaksiKeuanganModel transaction) {
    if (_filterJenis != null && transaction.jenis != _filterJenis) {
      return false;
    }

    final transactionDate = _dateOnly(transaction.tanggal);
    if (_filterFrom != null &&
        transactionDate.isBefore(_dateOnly(_filterFrom!))) {
      return false;
    }

    if (_filterTo != null &&
        transactionDate.isAfter(_dateOnly(_filterTo!))) {
      return false;
    }

    return true;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  void _sortTransactionsByDate() {
    _transactions.sort((a, b) => b.tanggal.compareTo(a.tanggal));
  }

  // ---------------------------------------------------------------------------
  // Pengelolaan error
  // ---------------------------------------------------------------------------

  void clearError() {
    _errorMessage = null;
    _detailErrorMessage = null;
    _loadMoreErrorMessage = null;
    _submitErrorMessage = null;
    _reportErrorMessage = null;
    _notify();
  }

  void clearSubmitError() {
    _submitErrorMessage = null;
    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _transaksiService.dispose();
    super.dispose();
  }
}
