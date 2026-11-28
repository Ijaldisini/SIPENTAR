import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/keuangan/alokasi_kas_model.dart';
import '../../services/keuangan/alokasi_kas_service.dart';

/// Controller untuk mengelola pembacaan ringkasan alokasi kas.
///
/// Backend hanya menyediakan data total pemasukan dan kas operasional
/// berdasarkan tanggal. Controller ini tidak menyimpan atau mengubah
/// persentase alokasi kas.
class AlokasiKasController extends ChangeNotifier {
  final AlokasiKasService _alokasiKasService;

  AlokasiKasController({AlokasiKasService? alokasiKasService})
    : _alokasiKasService = alokasiKasService ?? AlokasiKasService();

  AlokasiKasModel? _alokasiKas;
  AlokasiKasModel? get alokasiKas => _alokasiKas;

  /// Alias getter untuk penggunaan yang lebih eksplisit di View.
  AlokasiKasModel? get result => _alokasiKas;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _tanggalTerpilih;
  String? get tanggalTerpilih => _tanggalTerpilih;

  bool _isDisposed = false;

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Mengambil ringkasan alokasi kas untuk [tanggal] berformat YYYY-MM-DD.
  ///
  /// Mengembalikan true jika data berhasil diterima dari backend.
  Future<bool> loadAlokasiKas({required String tanggal}) async {
    if (_isLoading) return false;

    final normalizedDate = tanggal.trim();
    if (normalizedDate.isEmpty) {
      _errorMessage = 'Tanggal wajib diisi.';
      _notify();
      return false;
    }

    _isLoading = true;
    _alokasiKas = null;
    _tanggalTerpilih = normalizedDate;
    _errorMessage = null;
    _notify();

    try {
      _alokasiKas = await _alokasiKasService.getAlokasiKas(
        tanggal: normalizedDate,
      );
      _tanggalTerpilih = normalizedDate;
      _errorMessage = null;
      return true;
    } on AlokasiKasServiceException catch (e) {
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
      _errorMessage =
          e.message?.toString() ?? 'Format tanggal alokasi kas tidak valid.';
      return false;
    } catch (_) {
      _errorMessage = 'Gagal mengambil data alokasi kas. Silakan coba lagi.';
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Menghapus pesan error tanpa menghapus data yang sudah berhasil dimuat.
  void clearError() {
    _errorMessage = null;
    _notify();
  }

  /// Menghapus data dan pesan error, misalnya saat halaman ditutup/reset.
  void reset() {
    if (_isLoading) return;

    _alokasiKas = null;
    _tanggalTerpilih = null;
    _errorMessage = null;
    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _alokasiKasService.dispose();
    super.dispose();
  }
}
