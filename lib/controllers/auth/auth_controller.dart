import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth/user_model.dart';
import '../../services/auth/auth_service.dart';

enum SessionRestoreStatus { authenticated, unauthenticated, unavailable }

class AuthController extends ChangeNotifier {
  final AuthService _authService;

  AuthController({AuthService? authService})
    : _authService = authService ?? AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel? _user;
  UserModel? get user => _user;

  SessionRestoreStatus _sessionStatus = SessionRestoreStatus.unauthenticated;

  SessionRestoreStatus get sessionStatus => _sessionStatus;

  bool _isDisposed = false;

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty) {
      _errorMessage = 'Username wajib diisi.';
      _notify();
      return false;
    }

    if (password.isEmpty) {
      _errorMessage = 'Password wajib diisi.';
      _notify();
      return false;
    }

    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;

    _notify();

    try {
      final response = await _authService.login(
        username: username.trim(),
        password: password,
      );

      if (!response.success) {
        _errorMessage = _getResponseError(response.errors, response.message);

        return false;
      }

      if (response.user == null) {
        _errorMessage = 'Data pengguna tidak ditemukan.';
        return false;
      }

      _user = response.user;
      _isAuthenticated = true;
      _sessionStatus = SessionRestoreStatus.authenticated;
      _errorMessage = null;

      return true;
    } on TimeoutException {
      _errorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';

      return false;
    } on SocketException {
      _errorMessage = 'Tidak dapat terhubung ke server. Periksa jaringan.';

      return false;
    } on http.ClientException {
      _errorMessage = 'Tidak dapat terhubung ke server. Periksa jaringan.';

      return false;
    } on FormatException catch (e) {
      _errorMessage = e.message;

      return false;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan saat login. Silakan coba lagi.';

      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<SessionRestoreStatus> restoreSession() async {
    if (_isLoading) return _sessionStatus;

    _isLoading = true;
    _errorMessage = null;

    _notify();

    try {
      final currentUser = await _authService.getCurrentUser();

      if (currentUser == null) {
        _user = null;
        _isAuthenticated = false;

        _sessionStatus = SessionRestoreStatus.unauthenticated;

        return _sessionStatus;
      }

      _user = currentUser;
      _isAuthenticated = true;

      _sessionStatus = SessionRestoreStatus.authenticated;

      return _sessionStatus;
    } on TimeoutException {
      _errorMessage = 'Koneksi ke server timeout. Periksa jaringan.';

      _sessionStatus = SessionRestoreStatus.unavailable;

      return _sessionStatus;
    } on SocketException {
      _errorMessage = 'Server tidak dapat dijangkau. Periksa koneksi internet.';

      _sessionStatus = SessionRestoreStatus.unavailable;

      return _sessionStatus;
    } on http.ClientException {
      _errorMessage = 'Tidak dapat terhubung ke server.';

      _sessionStatus = SessionRestoreStatus.unavailable;

      return _sessionStatus;
    } on FormatException catch (e) {
      _errorMessage = e.message;

      _sessionStatus = SessionRestoreStatus.unavailable;

      return _sessionStatus;
    } catch (_) {
      _errorMessage = 'Gagal memeriksa sesi pengguna. Silakan coba lagi.';

      _sessionStatus = SessionRestoreStatus.unavailable;

      return _sessionStatus;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<bool> logout() async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;

    _notify();

    bool serverLogoutSucceeded = false;

    try {
      await _authService.logout();

      serverLogoutSucceeded = true;
    } on TimeoutException {
      _errorMessage = 'Sesi lokal diakhiri, tetapi server tidak merespons.';
    } on SocketException {
      _errorMessage =
          'Sesi lokal diakhiri, tetapi server tidak dapat dijangkau.';
    } on http.ClientException {
      _errorMessage = 'Sesi lokal diakhiri, tetapi koneksi ke server gagal.';
    } catch (_) {
      _errorMessage = 'Sesi lokal diakhiri, tetapi Logout server gagal.';
    } finally {
      _user = null;
      _isAuthenticated = false;

      _sessionStatus = SessionRestoreStatus.unauthenticated;

      _isLoading = false;

      _notify();
    }

    return serverLogoutSucceeded;
  }

  String _getResponseError(Map<String, dynamic>? errors, String message) {
    if (errors != null) {
      for (final error in errors.values) {
        if (error is List && error.isNotEmpty) {
          return error.first.toString();
        }

        if (error is String && error.isNotEmpty) {
          return error;
        }
      }
    }

    return message.isNotEmpty ? message : 'Login gagal. Silakan coba lagi.';
  }

  void clearError() {
    _errorMessage = null;
    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authService.dispose();

    super.dispose();
  }
}
