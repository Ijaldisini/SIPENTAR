import '../budidaya/budidaya_model.dart';

/// Model response untuk endpoint GET /diagnosis dan POST /diagnosis.
///
/// Backend mengembalikan satu image_url, hasil klasifikasi, confidence dalam
/// skala 0-100, rekomendasi, tanggal diagnosis, disclaimer, serta relasi user
/// dan budidaya. Upload multipart ditangani oleh DiagnosisService, bukan model.
class DiagnosisModel {
  static const String hasilSehat = 'sehat';
  static const String hasilBusukBatang = 'busuk_batang';
  static const String hasilCacarDaun = 'cacar_daun';
  static const String hasilBusukAkar = 'busuk_akar';

  static const String disclaimerDefault =
      'Hasil ini hanya informasi pendukung, bukan pengganti pemeriksaan langsung.';

  final int id;
  final int userId;
  final int budidayaId;
  final String imageUrl;
  final String hasil;
  /// Confidence dari backend, disimpan dalam skala persen 0 sampai 100.
  final double confidence;
  final String rekomendasi;
  final DateTime tanggalDiagnosis;
  final String disclaimer;
  final DiagnosisUserModel? user;
  final BudidayaModel? budidaya;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DiagnosisModel({
    required this.id,
    required this.userId,
    required this.budidayaId,
    required this.imageUrl,
    required this.hasil,
    required this.confidence,
    required this.rekomendasi,
    required this.tanggalDiagnosis,
    this.disclaimer = disclaimerDefault,
    this.user,
    this.budidaya,
    this.createdAt,
    this.updatedAt,
  });

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    final id = _readInt(json['id']);
    final userId = _readInt(json['user_id']);
    final budidayaId = _readInt(json['budidaya_id']);
    final imageUrl = json['image_url'];
    final hasil = json['hasil'];
    final confidence = _readDouble(json['confidence']);
    final rekomendasi = json['rekomendasi'];
    final tanggalDiagnosis = _readDate(json['tanggal_diagnosis']);
    final disclaimer = json['disclaimer'];

    if (id == null ||
        userId == null ||
        budidayaId == null ||
        imageUrl is! String ||
        imageUrl.trim().isEmpty ||
        hasil is! String ||
        hasil.trim().isEmpty ||
        confidence == null ||
        !confidence.isFinite ||
        confidence < 0 ||
        confidence > 100 ||
        rekomendasi is! String ||
        tanggalDiagnosis == null ||
        (disclaimer != null && disclaimer is! String)) {
      throw const FormatException('Format data diagnosis tidak valid.');
    }

    final userJson = _readMap(json['user']);
    final budidayaJson = _readMap(json['budidaya']);

    return DiagnosisModel(
      id: id,
      userId: userId,
      budidayaId: budidayaId,
      imageUrl: imageUrl,
      hasil: hasil,
      confidence: confidence,
      rekomendasi: rekomendasi,
      tanggalDiagnosis: tanggalDiagnosis,
      disclaimer: disclaimer as String? ?? disclaimerDefault,
      user: userJson == null ? null : DiagnosisUserModel.fromJson(userJson),
      budidaya: budidayaJson == null
          ? null
          : BudidayaModel.fromJson(budidayaJson),
      createdAt: _readDate(json['created_at']),
      updatedAt: _readDate(json['updated_at']),
    );
  }

  /// Label yang ditampilkan di UI tanpa mengubah nilai enum dari backend.
  String get hasilLabel {
    switch (hasil) {
      case hasilSehat:
        return 'Sehat';
      case hasilBusukBatang:
        return 'Busuk batang';
      case hasilCacarDaun:
        return 'Cacar daun';
      case hasilBusukAkar:
        return 'Busuk akar';
      default:
        return hasil.replaceAll('_', ' ');
    }
  }

  bool get isSehat => hasil == hasilSehat;

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _readDate(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;

    // DiagnosisResource menggunakan format "Y-m-d H:i:s" untuk kolom ini.
    // Format ISO dengan zona waktu juga tetap dapat diparsing oleh tryParse.
    final normalized = value.contains('T') ? value : value.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized);
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

class DiagnosisUserModel {
  final int id;
  final String nama;
  final String username;
  final String role;

  const DiagnosisUserModel({
    required this.id,
    required this.nama,
    required this.username,
    required this.role,
  });

  factory DiagnosisUserModel.fromJson(Map<String, dynamic> json) {
    final id = DiagnosisModel._readInt(json['id']);
    final nama = json['nama'];
    final username = json['username'];
    final role = json['role'];

    if (id == null ||
        nama is! String ||
        username is! String ||
        role is! String) {
      throw const FormatException('Format pengguna pada diagnosis tidak valid.');
    }

    return DiagnosisUserModel(
      id: id,
      nama: nama,
      username: username,
      role: role,
    );
  }
}
