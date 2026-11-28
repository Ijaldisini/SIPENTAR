import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/stok/stok_model.dart';
import '../../services/stok/stok_service.dart';

class StokController extends ChangeNotifier {
  final StokService _stokService;

  static const int _perPage = 15;

  StokController({StokService? stokService})
    : _stokService = stokService ?? StokService();

  List<StokModel> _stoks = [];
  List<StokModel> get stoks => List.unmodifiable(_stoks);

  StokModel? _selectedStok;
  StokModel? get selectedStok => _selectedStok;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isDetailLoading = false;
  bool get isDetailLoading => _isDetailLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _detailErrorMessage;
  String? get detailErrorMessage => _detailErrorMessage;

  String? _submitErrorMessage;
  String? get submitErrorMessage => _submitErrorMessage;

  String? _loadMoreErrorMessage;
  String? get loadMoreErrorMessage => _loadMoreErrorMessage;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _lastPage = 1;
  int get lastPage => _lastPage;

  int _totalStocks = 0;
  int get totalStocks => _totalStocks;

  bool get hasMoreStoks => _currentPage < _lastPage;

  bool _isDisposed = false;

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> loadStoks() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _loadMoreErrorMessage = null;

    _currentPage = 1;
    _lastPage = 1;
    _totalStocks = 0;

    _notify();

    try {
      final result = await _stokService.getStoksPage(
        page: 1,
        perPage: _perPage,
      );

      _stoks = result.stocks;
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _totalStocks = result.total;
    } on StokServiceException catch (e) {
      _errorMessage = e.message;
    } on TimeoutException {
      _errorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
    } on http.ClientException {
      _errorMessage =
          'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    } on FormatException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Gagal mengambil daftar stok.';
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<StokModel?> loadStokDetail({required int id}) async {
    if (_isDetailLoading) return null;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    _selectedStok = null;

    _notify();

    try {
      final stok = await _stokService.getStokById(id: id);

      _selectedStok = stok;

      return stok;
    } on StokServiceException catch (e) {
      _detailErrorMessage = e.message;
      return null;
    } on TimeoutException {
      _detailErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return null;
    } on http.ClientException {
      _detailErrorMessage =
          'Tidak dapat terhubung ke server. Periksa koneksi internet.';
      return null;
    } on FormatException catch (e) {
      _detailErrorMessage = e.message;
      return null;
    } catch (_) {
      _detailErrorMessage = 'Gagal mengambil detail stok.';
      return null;
    } finally {
      _isDetailLoading = false;
      _notify();
    }
  }

  Future<StokModel?> createStok({
    required String namaBahan,
    required String kategori,
    required String satuan,
    required double jumlahStok,
    required double batasMinimum,
  }) async {
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _submitErrorMessage = null;

    _notify();

    try {
      final stok = await _stokService.createStok(
        namaBahan: namaBahan,
        kategori: kategori,
        satuan: satuan,
        jumlahStok: jumlahStok,
        batasMinimum: batasMinimum,
      );

      _stoks = [stok, ..._stoks.where((item) => item.id != stok.id)];

      _totalStocks++;
      _lastPage = (_totalStocks / _perPage).ceil();

      return stok;
    } on StokServiceException catch (e) {
      _submitErrorMessage = e.message;
      return null;
    } on TimeoutException {
      _submitErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return null;
    } on http.ClientException {
      _submitErrorMessage =
          'Tidak dapat terhubung ke server. Periksa koneksi internet.';
      return null;
    } on FormatException catch (e) {
      _submitErrorMessage = e.message;
      return null;
    } catch (_) {
      _submitErrorMessage = 'Gagal menambahkan stok.';
      return null;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  Future<StokModel?> updateStok({
    required int id,
    required String namaBahan,
    required String kategori,
    required String satuan,
    required double jumlahStok,
    required double batasMinimum,
  }) async {
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _submitErrorMessage = null;

    _notify();

    try {
      final updatedStok = await _stokService.updateStok(
        id: id,
        namaBahan: namaBahan,
        kategori: kategori,
        satuan: satuan,
        jumlahStok: jumlahStok,
        batasMinimum: batasMinimum,
      );

      _stoks = _stoks.map((item) {
        return item.id == updatedStok.id ? updatedStok : item;
      }).toList();

      if (_selectedStok?.id == updatedStok.id) {
        _selectedStok = updatedStok;
      }

      return updatedStok;
    } on StokServiceException catch (e) {
      _submitErrorMessage = e.message;
      return null;
    } on TimeoutException {
      _submitErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return null;
    } on http.ClientException {
      _submitErrorMessage =
          'Tidak dapat terhubung ke server. Periksa koneksi internet.';
      return null;
    } on FormatException catch (e) {
      _submitErrorMessage = e.message;
      return null;
    } catch (_) {
      _submitErrorMessage = 'Gagal memperbarui stok.';
      return null;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  Future<bool> deleteStok({required int id}) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _submitErrorMessage = null;

    _notify();

    try {
      await _stokService.deleteStok(id: id);

      _stoks = _stoks.where((item) => item.id != id).toList();

      if (_selectedStok?.id == id) {
        _selectedStok = null;
      }

      _totalStocks = (_totalStocks - 1).clamp(0, 999999);

      _lastPage = _totalStocks == 0 ? 1 : (_totalStocks / _perPage).ceil();

      if (_currentPage > _lastPage) {
        _currentPage = _lastPage;
      }

      return true;
    } on StokServiceException catch (e) {
      _submitErrorMessage = e.message;
      return false;
    } on TimeoutException {
      _submitErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return false;
    } on http.ClientException {
      _submitErrorMessage =
          'Tidak dapat terhubung ke server. Periksa koneksi internet.';
      return false;
    } on FormatException catch (e) {
      _submitErrorMessage = e.message;
      return false;
    } catch (_) {
      _submitErrorMessage = 'Gagal menghapus stok.';
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  Future<void> loadMoreStoks() async {
    if (_isLoading || _isLoadingMore || !hasMoreStoks) {
      return;
    }

    _isLoadingMore = true;
    _loadMoreErrorMessage = null;

    _notify();

    try {
      final result = await _stokService.getStoksPage(
        page: _currentPage + 1,
        perPage: _perPage,
      );

      final existingIds = _stoks.map((item) => item.id).toSet();

      final newStoks = result.stocks.where(
        (item) => !existingIds.contains(item.id),
      );

      _stoks = [..._stoks, ...newStoks];

      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _totalStocks = result.total;
    } on StokServiceException catch (e) {
      _loadMoreErrorMessage = e.message;
    } on TimeoutException {
      _loadMoreErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
    } on http.ClientException {
      _loadMoreErrorMessage =
          'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    } on FormatException catch (e) {
      _loadMoreErrorMessage = e.message;
    } catch (_) {
      _loadMoreErrorMessage = 'Gagal memuat stok berikutnya.';
    } finally {
      _isLoadingMore = false;
      _notify();
    }
  }

  void clearError() {
    _errorMessage = null;
    _detailErrorMessage = null;
    _submitErrorMessage = null;
    _loadMoreErrorMessage = null;

    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stokService.dispose();

    super.dispose();
  }
}
