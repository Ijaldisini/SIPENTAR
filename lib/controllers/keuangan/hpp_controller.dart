import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/keuangan/hpp_model.dart';
import '../../services/keuangan/hpp_service.dart';

/// Controller untuk mengelola proses kalkulasi HPP.
///
/// Controller ini hanya mengelola state dan memanggil HppService.
/// Perhitungan HPP tetap dilakukan oleh backend SIPENTAR.
class HppController extends ChangeNotifier {
  final HppService _hppService;

  HppController({HppService? hppService})
    : _hppService = hppService ?? HppService();

  HppModel? _hasilHpp;
  HppModel? get hasilHpp => _hasilHpp;

  /// Alias getter agar mudah dipakai dengan penamaan berbahasa Inggris.
  HppModel? get result => _hasilHpp;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false;

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Meminta backend menghitung HPP.
  ///
  /// Isi [lubang] untuk menghitung berdasarkan jumlah lubang tertentu, atau
  /// [panenId] untuk mengambil jumlah lubang dari data panen terkait.
  /// Jika keduanya null, backend menggunakan total kapasitas lubang dari
  /// seluruh meja tanam. Backend memprioritaskan [panenId] bila keduanya diisi.
  ///
  /// Mengembalikan true apabila kalkulasi berhasil.
  Future<bool> calculateHpp({
    int? lubang,
    int? panenId,
  }) async {
    if (_isLoading) return false;

    if (lubang != null && lubang < 1) {
      _errorMessage = 'Jumlah lubang tanam harus lebih besar dari 0.';
      _notify();
      return false;
    }

    if (panenId != null && panenId < 1) {
      _errorMessage = 'ID panen harus lebih besar dari 0.';
      _notify();
      return false;
    }

    _isLoading = true;
    _hasilHpp = null;
    _errorMessage = null;
    _notify();

    try {
      _hasilHpp = await _hppService.calculateHpp(
        lubang: lubang,
        panenId: panenId,
      );
      _errorMessage = null;
      return true;
    } on HppServiceException catch (e) {
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
      _errorMessage = e.message?.toString() ?? 'Parameter kalkulasi HPP tidak valid.';
      return false;
    } catch (_) {
      _errorMessage = 'Gagal menghitung HPP. Silakan coba lagi.';
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Menghapus pesan error tanpa mengubah hasil kalkulasi.
  void clearError() {
    _errorMessage = null;
    _notify();
  }

  /// Menghapus hasil dan pesan error, misalnya saat form direset.
  void reset() {
    if (_isLoading) return;

    _hasilHpp = null;
    _errorMessage = null;
    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _hppService.dispose();
    super.dispose();
  }
}
