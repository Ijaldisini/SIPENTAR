/// Model respons kalkulasi HPP dari endpoint GET /keuangan/hpp.
///
/// Bentuk data backend:
/// {
///   "lubang": 100,
///   "hpp_per_lubang": "1200",
///   "total_hpp": "120000.00"
/// }
class HppModel {
  final int lubang;
  final double hppPerLubang;
  final double totalHpp;

  const HppModel({
    required this.lubang,
    required this.hppPerLubang,
    required this.totalHpp,
  });

  factory HppModel.fromJson(Map<String, dynamic> json) {
    final lubang = _parseInt(json['lubang']);
    final hppPerLubang = _parseDouble(json['hpp_per_lubang']);
    final totalHpp = _parseDouble(json['total_hpp']);

    if (lubang == null || lubang < 0) {
      throw const FormatException('Jumlah lubang dari server tidak valid.');
    }

    if (hppPerLubang == null || hppPerLubang < 0) {
      throw const FormatException('Nilai HPP per lubang dari server tidak valid.');
    }

    if (totalHpp == null || totalHpp < 0) {
      throw const FormatException('Total HPP dari server tidak valid.');
    }

    return HppModel(
      lubang: lubang,
      hppPerLubang: hppPerLubang,
      totalHpp: totalHpp,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
