import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth/user_model.dart';
import '../../services/auth/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;

  AuthController({AuthService? authService})
    : _authService = authService ?? AuthService();

  // State login
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Status autentikasi
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // Pesan error
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Data pengguna
  UserModel? _user;
  UserModel? get user => _user;

  // Proses login
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    // Validasi input kosong
    if (username.trim().isEmpty) {
      _errorMessage = 'Username wajib diisi.';
      notifyListeners();
      return false;
    }

    if (password.isEmpty) {
      _errorMessage = 'Password wajib diisi.';
      notifyListeners();
      return false;
    }

    // Mencegah request login berulang
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      // Memanggil AuthService
      final response = await _authService.login(
        username: username.trim(),
        password: password,
      );

      // Jika login gagal
      if (!response.success) {
        _errorMessage = _getResponseError(response.errors, response.message);

        return false;
      }

      // Memastikan data pengguna tersedia
      if (response.user == null) {
        _errorMessage = 'Data pengguna tidak ditemukan.';
        return false;
      }

      // Login berhasil
      _user = response.user;
      _isAuthenticated = true;
      _errorMessage = null;

      return true;
    } on TimeoutException {
      _errorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';

      return false;
    } on http.ClientException {
      _errorMessage =
          'Tidak dapat terhubung ke server. Periksa koneksi internet.';

      return false;
    } on FormatException catch (e) {
      _errorMessage = e.message;

      return false;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan saat login. Silakan coba lagi.';

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengambil pesan error validasi dari Laravel
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

  // Menghapus pesan error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Membersihkan resource
  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
