import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/dashboard/dashboard_summary_model.dart';
import '../../services/dashboard/dashboard_service.dart';

/// Controller untuk memuat dan mengelola state ringkasan Beranda SIPENTAR.
///
/// Controller tidak melakukan request HTTP secara langsung. Semua pengambilan
/// data dilakukan oleh [DashboardService], sedangkan controller mengelola
/// loading, error, role aktif, dan hasil ringkasan untuk View.
class DashboardController extends ChangeNotifier {
  final DashboardService _dashboardService;

  DashboardController({DashboardService? dashboardService})
    : _dashboardService = dashboardService ?? DashboardService();

  DashboardSummaryModel? _summary;
  DashboardSummaryModel? get summary => _summary;

  /// Alias eksplisit untuk View yang ingin menggunakan nama dashboard.
  DashboardSummaryModel? get dashboard => _summary;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _role;
  String? get role => _role;

  DateTime? _lastUpdatedAt;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  bool get hasData => _summary != null;
  bool get isOwner => _role == 'pemilik';
  bool get isEmployee => _role == 'pegawai';

  bool _isDisposed = false;
  int _requestVersion = 0;

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Memuat seluruh ringkasan dashboard sesuai role pengguna.
  ///
  /// Untuk role `pegawai`, [DashboardService] tidak meminta data keuangan dan
  /// karyawan. Jika role berubah, ringkasan role sebelumnya dibersihkan agar
  /// data khusus pemilik tidak tertinggal di state pegawai.
  Future<bool> loadDashboard({
    required String role,
    DateTime? referenceDate,
  }) async {
    if (_isDisposed || _isLoading) return false;

    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole != 'pemilik' && normalizedRole != 'pegawai') {
      _errorMessage = 'Role pengguna tidak dikenali.';
      _notify();
      return false;
    }

    if (_role != null && _role != normalizedRole) {
      _summary = null;
      _lastUpdatedAt = null;
    }

    _role = normalizedRole;
    _isLoading = true;
    _errorMessage = null;

    final requestVersion = ++_requestVersion;
    _notify();

    try {
      final result = await _dashboardService.getDashboardSummary(
        role: normalizedRole,
        referenceDate: referenceDate,
      );

      if (_isDisposed || requestVersion != _requestVersion) return false;

      _summary = result;
      _lastUpdatedAt = DateTime.now();
      _errorMessage = null;
      return true;
    } on DashboardServiceException catch (error) {
      _setErrorIfCurrent(requestVersion, error.message);
      return false;
    } on TimeoutException {
      _setErrorIfCurrent(
        requestVersion,
        'Koneksi ke server timeout. Silakan coba lagi.',
      );
      return false;
    } on SocketException {
      _setErrorIfCurrent(
        requestVersion,
        'Server tidak dapat dijangkau. Periksa koneksi internet.',
      );
      return false;
    } on http.ClientException {
      _setErrorIfCurrent(
        requestVersion,
        'Tidak dapat terhubung ke server. Periksa jaringan.',
      );
      return false;
    } on FormatException catch (error) {
      _setErrorIfCurrent(requestVersion, error.message);
      return false;
    } on ArgumentError catch (error) {
      _setErrorIfCurrent(
        requestVersion,
        error.message?.toString() ?? 'Parameter dashboard tidak valid.',
      );
      return false;
    } catch (_) {
      _setErrorIfCurrent(
        requestVersion,
        'Gagal memuat Beranda. Silakan coba lagi.',
      );
      return false;
    } finally {
      if (!_isDisposed && requestVersion == _requestVersion) {
        _isLoading = false;
        _notify();
      }
    }
  }

  /// Memuat ulang dashboard menggunakan role yang terakhir dipakai.
  ///
  /// [referenceDate] opsional, misalnya untuk pengujian tanggal tertentu.
  /// Jika tidak diberikan, service menggunakan tanggal saat ini.
  Future<bool> refreshDashboard({DateTime? referenceDate}) {
    final activeRole = _role;
    if (activeRole == null) {
      _errorMessage =
          'Role pengguna belum tersedia. Muat dashboard terlebih dahulu.';
      _notify();
      return Future<bool>.value(false);
    }

    return loadDashboard(role: activeRole, referenceDate: referenceDate);
  }

  void _setErrorIfCurrent(int requestVersion, String message) {
    if (_isDisposed || requestVersion != _requestVersion) return;
    _errorMessage = message.trim().isEmpty
        ? 'Gagal memuat Beranda. Silakan coba lagi.'
        : message;
  }

  /// Menghapus pesan error tanpa menghapus ringkasan yang sudah berhasil.
  void clearError() {
    _errorMessage = null;
    _notify();
  }

  /// Menghapus seluruh state controller.
  ///
  /// Versi request dinaikkan supaya hasil request lama yang masih berjalan
  /// tidak menimpa state setelah controller di-reset.
  void reset() {
    _requestVersion++;
    _summary = null;
    _isLoading = false;
    _errorMessage = null;
    _role = null;
    _lastUpdatedAt = null;
    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _requestVersion++;
    _dashboardService.dispose();
    super.dispose();
  }
}
