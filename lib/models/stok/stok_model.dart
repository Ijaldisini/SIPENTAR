class StokModel {
  final int id;
  final String namaBahan;
  final String kategori;
  final String satuan;
  final double jumlahStok;
  final double batasMinimum;
  final bool isLow;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StokModel({
    required this.id,
    required this.namaBahan,
    required this.kategori,
    required this.satuan,
    required this.jumlahStok,
    required this.batasMinimum,
    required this.isLow,
    this.createdAt,
    this.updatedAt,
  });

  factory StokModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];

    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    if (id == null) {
      throw const FormatException('ID stok tidak valid.');
    }

    final jumlahStok = _parseDouble(json['jumlah_stok'], 'jumlah_stok');

    final batasMinimum = _parseDouble(json['batas_minimum'], 'batas_minimum');

    final rawIsLow = json['is_low'];

    return StokModel(
      id: id,
      namaBahan: _parseString(json['nama_bahan'], 'nama_bahan'),
      kategori: _parseString(json['kategori'], 'kategori'),
      satuan: _parseString(json['satuan'], 'satuan'),
      jumlahStok: jumlahStok,
      batasMinimum: batasMinimum,
      isLow: rawIsLow is bool ? rawIsLow : jumlahStok <= batasMinimum,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static double _parseDouble(dynamic value, String field) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    throw FormatException('Format $field tidak valid.');
  }

  static String _parseString(dynamic value, String field) {
    if (value is String) {
      return value;
    }

    throw FormatException('Format $field tidak valid.');
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value == '') {
      return null;
    }

    if (value is String) {
      final date = DateTime.tryParse(value);

      if (date != null) {
        return date;
      }
    }

    throw const FormatException('Format tanggal stok tidak valid.');
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'nama_bahan': namaBahan,
      'kategori': kategori,
      'satuan': satuan,
      'jumlah_stok': jumlahStok,
      'batas_minimum': batasMinimum,
    };
  }
}
