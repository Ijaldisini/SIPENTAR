/// Model ringkasan laporan keuangan dari endpoint GET /keuangan/laporan.
///
/// Seluruh total merupakan agregat untuk periode `from` sampai `to`, bukan
/// saldo berjalan sepanjang umur usaha.
class LaporanKeuanganModel {
  final DateTime tanggalMulai;
  final DateTime tanggalAkhir;
  final double totalPemasukan;
  final double totalPengeluaran;
  final double totalKasOperasional;
  final double totalLabaBersih;
  final double selisih;

  const LaporanKeuanganModel({
    required this.tanggalMulai,
    required this.tanggalAkhir,
    required this.totalPemasukan,
    required this.totalPengeluaran,
    required this.totalKasOperasional,
    required this.totalLabaBersih,
    required this.selisih,
  });

  factory LaporanKeuanganModel.fromJson(Map<String, dynamic> json) {
    final rawPeriod = json['periode'];
    if (rawPeriod is! Map) {
      throw const FormatException('Periode laporan keuangan tidak ditemukan.');
    }

    final period = Map<String, dynamic>.from(rawPeriod);

    return LaporanKeuanganModel(
      tanggalMulai: _parseDate(period['from'], 'periode.from'),
      tanggalAkhir: _parseDate(period['to'], 'periode.to'),
      totalPemasukan: _parseNumber(json['total_pemasukan'], 'total_pemasukan'),
      totalPengeluaran: _parseNumber(
        json['total_pengeluaran'],
        'total_pengeluaran',
      ),
      totalKasOperasional: _parseNumber(
        json['total_kas_operasional'],
        'total_kas_operasional',
      ),
      totalLabaBersih: _parseNumber(
        json['total_laba_bersih'],
        'total_laba_bersih',
      ),
      selisih: _parseNumber(json['selisih'], 'selisih'),
    );
  }

  static double _parseNumber(dynamic value, String field) {
    if (value is num && value.isFinite) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
      if (parsed != null && parsed.isFinite) return parsed;
    }
    throw FormatException('Field "$field" harus berupa angka.');
  }

  static DateTime _parseDate(dynamic value, String field) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Field "$field" harus berisi tanggal.');
    }
    try {
      return DateTime.parse(value);
    } on FormatException {
      throw FormatException('Format tanggal pada field "$field" tidak valid.');
    }
  }
}
