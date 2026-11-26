import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth/user_model.dart';
import '../../services/akun/profil_service.dart';

class ProfilController extends ChangeNotifier {
  final ProfilService _profilService;

  ProfilController({ProfilService? profilService})
    : _profilService = profilService ?? ProfilService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel? _updatedUser;
  UserModel? get updatedUser => _updatedUser;

  bool _isDisposed = false;

  Future<UserModel?> updateProfile({
    required String nama,
    required String username,
    String? password,
  }) async {
    if (_isLoading) return null;

    _isLoading = true;
    _errorMessage = null;
    _updatedUser = null;

    notifyListeners();

    try {
      final user = await _profilService.updateProfile(
        nama: nama,
        username: username,
        password: password,
      );

      _updatedUser = user;
      return user;
    } on ProfilServiceException catch (e) {
      _errorMessage = e.message;
      return null;
    } on TimeoutException {
      _errorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
      return null;
    } on http.ClientException {
      _errorMessage =
          'Tidak dapat terhubung ke server. Periksa koneksi internet.';
      return null;
    } on FormatException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan saat memperbarui profil.';
      return null;
    } finally {
      _isLoading = false;

      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  void clearError() {
    _errorMessage = null;

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _profilService.dispose();
    super.dispose();
  }
}
