class TransaksiKeuanganModel {
  final int id;
  final int userId;
  final int? panenId;
  final String jenis;
  final DateTime tanggal;
  final double jumlah;
  final double? persentaseKas;
  final double? kasOperasional;
  final double? labaBersih;
  final String? keterangan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TransaksiKeuanganModel({
    required this.id,
    required this.userId,
    this.panenId,
    required this.jenis,
    required this.tanggal,
    required this.jumlah,
    this.persentaseKas,
    this.kasOperasional,
    this.labaBersih,
    this.keterangan,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPemasukan => jenis == 'pemasukan';

  bool get isPengeluaran => jenis == 'pengeluaran';

  factory TransaksiKeuanganModel.fromJson(Map<String, dynamic> json) {
    final jenis = _parseRequiredString(json['jenis'], 'jenis');

    if (jenis != 'pemasukan' && jenis != 'pengeluaran') {
      throw FormatException(
        'Nilai jenis transaksi tidak dikenal: $jenis. '
        'Nilai yang didukung adalah pemasukan atau pengeluaran.',
      );
    }

    return TransaksiKeuanganModel(
      id: _parseRequiredInt(json['id'], 'id'),
      userId: _parseRequiredInt(json['user_id'], 'user_id'),
      panenId: _parseNullableInt(json['panen_id'], 'panen_id'),
      jenis: jenis,
      tanggal: _parseRequiredDate(json['tanggal'], 'tanggal'),
      jumlah: _parseRequiredDouble(json['jumlah'], 'jumlah'),
      persentaseKas: _parseNullableDouble(
        json['persentase_kas'],
        'persentase_kas',
      ),
      kasOperasional: _parseNullableDouble(
        json['kas_operasional'],
        'kas_operasional',
      ),
      labaBersih: _parseNullableDouble(json['laba_bersih'], 'laba_bersih'),
      keterangan: _parseNullableString(json['keterangan'], 'keterangan'),
      createdAt: _parseNullableDate(json['created_at'], 'created_at'),
      updatedAt: _parseNullableDate(json['updated_at'], 'updated_at'),
    );
  }

  /// Mengubah model menjadi payload request POST/PUT API transaksi keuangan.
  ///
  /// user_id, kas_operasional, dan laba_bersih tidak dikirim karena backend
  /// mengisi user_id dari sesi login dan menghitung nilai kas secara otomatis.
  Map<String, dynamic> toRequestJson() {
    if (jenis != 'pemasukan' && jenis != 'pengeluaran') {
      throw FormatException(
        'Jenis transaksi harus pemasukan atau pengeluaran.',
      );
    }

    return {
      'jenis': jenis,
      'tanggal': _formatDate(tanggal),
      'jumlah': jumlah,
      'panen_id': panenId,
      'persentase_kas': isPemasukan ? persentaseKas : null,
      'keterangan': keterangan,
    };
  }

  static int _parseRequiredInt(dynamic value, String field) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }

    throw FormatException('Field "$field" harus berupa bilangan bulat.');
  }

  static int? _parseNullableInt(dynamic value, String field) {
    if (value == null || value == '') return null;
    return _parseRequiredInt(value, field);
  }

  static double _parseRequiredDouble(dynamic value, String field) {
    final parsed = _parseNullableDouble(value, field);
    if (parsed == null) {
      throw FormatException('Field "$field" wajib berisi angka.');
    }
    return parsed;
  }

  static double? _parseNullableDouble(dynamic value, String field) {
    if (value == null || value == '') return null;
    if (value is num) return value.toDouble();

    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      final parsed = double.tryParse(normalized);
      if (parsed != null && parsed.isFinite) return parsed;
    }

    throw FormatException('Field "$field" harus berupa angka.');
  }

  static String _parseRequiredString(dynamic value, String field) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    throw FormatException('Field "$field" wajib berupa teks.');
  }

  static String? _parseNullableString(dynamic value, String field) {
    if (value == null) return null;
    if (value is String) {
      final normalized = value.trim();
      return normalized.isEmpty ? null : normalized;
    }

    throw FormatException('Field "$field" harus berupa teks atau null.');
  }

  static DateTime _parseRequiredDate(dynamic value, String field) {
    final parsed = _parseNullableDate(value, field);
    if (parsed == null) {
      throw FormatException('Field "$field" wajib berisi tanggal.');
    }
    return parsed;
  }

  static DateTime? _parseNullableDate(dynamic value, String field) {
    if (value == null || value == '') return null;
    if (value is! String) {
      throw FormatException('Field "$field" harus berupa teks tanggal.');
    }

    try {
      return DateTime.parse(value).toLocal();
    } on FormatException {
      throw FormatException('Format tanggal pada field "$field" tidak valid.');
    }
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
