class AlokasiKasModel {
  final String tanggal;
  final double totalPemasukan;
  final double totalKasOperasional;

  const AlokasiKasModel({
    required this.tanggal,
    required this.totalPemasukan,
    required this.totalKasOperasional,
  });

  factory AlokasiKasModel.fromJson(Map<String, dynamic> json) {
    final tanggalValue = json['tanggal'];
    if (tanggalValue is! String || tanggalValue.trim().isEmpty) {
      throw const FormatException('Tanggal alokasi kas tidak valid.');
    }

    return AlokasiKasModel(
      tanggal: tanggalValue,
      totalPemasukan: _parseAmount(json['total_pemasukan'], 'total_pemasukan'),
      totalKasOperasional: _parseAmount(
        json['total_kas_operasional'],
        'total_kas_operasional',
      ),
    );
  }

  static double _parseAmount(dynamic value, String fieldName) {
    if (value is num) return value.toDouble();

    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }

    throw FormatException('Field $fieldName tidak berisi nominal yang valid.');
  }

  Map<String, dynamic> toJson() {
    return {
      'tanggal': tanggal,
      'total_pemasukan': totalPemasukan,
      'total_kas_operasional': totalKasOperasional,
    };
  }
}
