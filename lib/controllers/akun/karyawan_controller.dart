import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth/user_model.dart';
import '../../services/akun/karyawan_service.dart';

class KaryawanController extends ChangeNotifier {
  final KaryawanService _karyawanService;
  static const int _perPage = 15;

  KaryawanController({KaryawanService? karyawanService})
    : _karyawanService = karyawanService ?? KaryawanService();

  List<UserModel> _employees = [];
  List<UserModel> get employees => _employees;

  UserModel? _selectedEmployee;
  UserModel? get selectedEmployee => _selectedEmployee;

  bool _isDetailLoading = false;
  bool get isDetailLoading => _isDetailLoading;

  String? _detailErrorMessage;
  String? get detailErrorMessage => _detailErrorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _lastPage = 1;
  int get lastPage => _lastPage;

  int _totalEmployees = 0;
  int get totalEmployees => _totalEmployees;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _loadMoreErrorMessage;
  String? get loadMoreErrorMessage => _loadMoreErrorMessage;

  bool get hasMoreEmployees => _currentPage < _lastPage;

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> loadEmployees() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _loadMoreErrorMessage = null;
    _currentPage = 1;
    _lastPage = 1;
    _totalEmployees = 0;

    _notify();

    try {
      final result = await _karyawanService.getEmployeesPage(page: 1);

      _employees = result.employees;
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _totalEmployees = result.total;
    } on KaryawanServiceException catch (e) {
      _errorMessage = e.message;
    } on TimeoutException {
      _errorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
    } on http.ClientException {
      _errorMessage =
          'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    } on FormatException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Gagal mengambil daftar karyawan.';
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<UserModel?> createEmployee({
    required String nama,
    required String username,
    required String password,
  }) async {
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _errorMessage = null;
    _notify();

    try {
      final employee = await _karyawanService.createEmployee(
        nama: nama,
        username: username,
        password: password,
      );

      _employees = [
        ..._employees.where((item) => item.id != employee.id),
        employee,
      ];

      _totalEmployees++;
      _lastPage = (_totalEmployees / _perPage).ceil();

      return employee;
    } on KaryawanServiceException catch (e) {
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
      _errorMessage = 'Gagal menambahkan karyawan.';
      return null;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  Future<UserModel?> updateEmployee({
    required int id,
    required String nama,
    required String username,
    String? password,
  }) async {
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _errorMessage = null;
    _notify();

    try {
      final updatedEmployee = await _karyawanService.updateEmployee(
        id: id,
        nama: nama,
        username: username,
        password: password,
      );

      _employees = _employees.map((employee) {
        return employee.id == updatedEmployee.id ? updatedEmployee : employee;
      }).toList();

      if (_selectedEmployee?.id == updatedEmployee.id) {
        _selectedEmployee = updatedEmployee;
      }

      return updatedEmployee;
    } on KaryawanServiceException catch (e) {
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
      _errorMessage = 'Gagal memperbarui data karyawan.';
      return null;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  Future<UserModel?> loadEmployeeDetail({required int id}) async {
    if (_isDetailLoading) return null;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    _selectedEmployee = null;

    _notify();

    try {
      final employee = await _karyawanService.getEmployeeById(id: id);

      _selectedEmployee = employee;

      return employee;
    } on KaryawanServiceException catch (e) {
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
      _detailErrorMessage = 'Gagal mengambil detail karyawan.';
      return null;
    } finally {
      _isDetailLoading = false;
      _notify();
    }
  }

  void clearError() {
    _errorMessage = null;
    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _karyawanService.dispose();
    super.dispose();
  }

  Future<void> loadMoreEmployees() async {
    if (_isLoading || _isLoadingMore || !hasMoreEmployees) {
      return;
    }

    _isLoadingMore = true;
    _loadMoreErrorMessage = null;
    _notify();

    try {
      final result = await _karyawanService.getEmployeesPage(
        page: _currentPage + 1,
      );

      final existingIds = _employees.map((item) => item.id).toSet();

      final newEmployees = result.employees.where(
        (item) => !existingIds.contains(item.id),
      );

      _employees = [..._employees, ...newEmployees];

      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _totalEmployees = result.total;
    } on KaryawanServiceException catch (e) {
      _loadMoreErrorMessage = e.message;
    } on TimeoutException {
      _loadMoreErrorMessage = 'Koneksi ke server timeout. Silakan coba lagi.';
    } on http.ClientException {
      _loadMoreErrorMessage =
          'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    } on FormatException catch (e) {
      _loadMoreErrorMessage = e.message;
    } catch (_) {
      _loadMoreErrorMessage = 'Gagal memuat karyawan berikutnya.';
    } finally {
      _isLoadingMore = false;
      _notify();
    }
  }
}
