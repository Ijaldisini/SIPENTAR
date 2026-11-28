import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/budidaya/budidaya_model.dart';
import '../../services/budidaya/meja_tanam_service.dart';

/// State controller daftar meja tanam yang dipakai pada form budidaya.
class MejaTanamController extends ChangeNotifier {
  final MejaTanamService _service;

  MejaTanamController({MejaTanamService? service})
    : _service = service ?? MejaTanamService();

  List<BudidayaMejaModel> _mejaTanams = [];
  List<BudidayaMejaModel> get mejaTanams => List.unmodifiable(_mejaTanams);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false;

  /// Meja dengan status `terisi` tidak ditawarkan untuk budidaya baru.
  /// Status selain `terisi` tetap ditampilkan karena backend juga dapat
  /// mengembalikan status awal seperti `kosong` atau `tersedia`.
  List<BudidayaMejaModel> get mejaTersedia => _mejaTanams
      .where((meja) => meja.status.toLowerCase() != 'terisi')
      .toList(growable: false);

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  Future<bool> loadMejaTanams({bool forceRefresh = false}) async {
    if (_isLoading) return false;
    if (_mejaTanams.isNotEmpty && !forceRefresh) return true;

    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      _mejaTanams = await _service.getMejaTanams();
      _errorMessage = null;
      return true;
    } on MejaTanamServiceException catch (e) {
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
      _errorMessage = e.message?.toString() ?? 'Parameter meja tanam tidak valid.';
      return false;
    } catch (_) {
      _errorMessage = 'Gagal mengambil daftar meja tanam.';
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<bool> refreshMejaTanams() => loadMejaTanams(forceRefresh: true);

  @override
  void dispose() {
    _isDisposed = true;
    _service.dispose();
    super.dispose();
  }
}
