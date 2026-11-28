import '../budidaya/budidaya_model.dart';

class PanenModel {
  static const String statusTerjadwal = 'terjadwal';
  static const String statusSelesai = 'selesai';

  /// Berat panen valid jika berupa angka finite dan minimal 0,01 kg.
  static bool isValidBeratKg(double? value) =>
      value != null && value.isFinite && value >= 0.01;

  final int id;
  final int budidayaId;
  final DateTime tanggalPanen;
  final double? beratKg;
  final String status;
  final BudidayaModel? budidaya;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PanenModel({
    required this.id,
    required this.budidayaId,
    required this.tanggalPanen,
    required this.beratKg,
    required this.status,
    this.budidaya,
    this.createdAt,
    this.updatedAt,
  });

  factory PanenModel.fromJson(Map<String, dynamic> json) {
    final id = _readInt(json['id']);
    final budidayaId = _readInt(json['budidaya_id']);
    final tanggalPanen = _readDate(json['tanggal_panen']);
    final status = json['status'];

    if (id == null ||
        budidayaId == null ||
        tanggalPanen == null ||
        status is! String) {
      throw const FormatException('Format data panen tidak valid.');
    }

    final budidayaJson = _readMap(json['budidaya']);

    return PanenModel(
      id: id,
      budidayaId: budidayaId,
      tanggalPanen: tanggalPanen,
      beratKg: _readDouble(json['berat_kg']),
      status: status,
      budidaya: budidayaJson == null
          ? null
          : BudidayaModel.fromJson(budidayaJson),
      createdAt: _readDate(json['created_at']),
      updatedAt: _readDate(json['updated_at']),
    );
  }

  /// Payload untuk POST /panen dan PUT /panen/{id}.
  /// berat_kg boleh null untuk status terjadwal, tetapi wajib diisi
  /// backend ketika status diubah menjadi selesai.
  Map<String, dynamic> toRequestJson() {
    return {
      'budidaya_id': budidayaId,
      'tanggal_panen': _formatDate(tanggalPanen),
      'berat_kg': beratKg,
      'status': status,
    };
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _readDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
