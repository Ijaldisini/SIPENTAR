class BudidayaModel {
  static const String statusBerjalan = 'berjalan';
  static const String statusSelesai = 'selesai';

  final int id;
  final int userId;
  final int mejaId;
  final DateTime tanggalSemai;
  final int jumlahTanaman;
  final String status;
  final int hss;
  final BudidayaUserModel? user;
  final BudidayaMejaModel? meja;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BudidayaModel({
    required this.id,
    required this.userId,
    required this.mejaId,
    required this.tanggalSemai,
    required this.jumlahTanaman,
    required this.status,
    required this.hss,
    this.user,
    this.meja,
    this.createdAt,
    this.updatedAt,
  });

  factory BudidayaModel.fromJson(Map<String, dynamic> json) {
    final id = _readInt(json['id']);
    final userId = _readInt(json['user_id']);
    final mejaId = _readInt(json['meja_id']);
    final jumlahTanaman = _readInt(json['jumlah_tanaman']);
    final hss = _readInt(json['hss']);
    final tanggalSemai = _readDate(json['tanggal_semai']);
    final status = json['status'];

    if (id == null ||
        userId == null ||
        mejaId == null ||
        jumlahTanaman == null ||
        hss == null ||
        tanggalSemai == null ||
        status is! String) {
      throw const FormatException('Format data budidaya tidak valid.');
    }

    final userJson = json['user'];
    final mejaJson = json['meja'];

    return BudidayaModel(
      id: id,
      userId: userId,
      mejaId: mejaId,
      tanggalSemai: tanggalSemai,
      jumlahTanaman: jumlahTanaman,
      status: status,
      hss: hss,
      user: userJson is Map<String, dynamic>
          ? BudidayaUserModel.fromJson(userJson)
          : null,
      meja: mejaJson is Map<String, dynamic>
          ? BudidayaMejaModel.fromJson(mejaJson)
          : null,
      createdAt: _readDate(json['created_at']),
      updatedAt: _readDate(json['updated_at']),
    );
  }

  /// Payload untuk POST /budidaya dan PUT /budidaya/{id}.
  /// user_id tidak dikirim karena diisi otomatis oleh backend dari sesi login.
  Map<String, dynamic> toRequestJson() {
    return {
      'meja_id': mejaId,
      'tanggal_semai': _formatDate(tanggalSemai),
      'jumlah_tanaman': jumlahTanaman,
      'status': status,
    };
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _readDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class BudidayaUserModel {
  final int id;
  final String nama;
  final String username;
  final String role;

  const BudidayaUserModel({
    required this.id,
    required this.nama,
    required this.username,
    required this.role,
  });

  factory BudidayaUserModel.fromJson(Map<String, dynamic> json) {
    final id = BudidayaModel._readInt(json['id']);
    final nama = json['nama'];
    final username = json['username'];
    final role = json['role'];

    if (id == null ||
        nama is! String ||
        username is! String ||
        role is! String) {
      throw const FormatException('Format data pengguna budidaya tidak valid.');
    }

    return BudidayaUserModel(
      id: id,
      nama: nama,
      username: username,
      role: role,
    );
  }
}

class BudidayaMejaModel {
  final int id;
  final int nomorMeja;
  final int kapasitasLubang;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BudidayaMejaModel({
    required this.id,
    required this.nomorMeja,
    required this.kapasitasLubang,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory BudidayaMejaModel.fromJson(Map<String, dynamic> json) {
    final id = BudidayaModel._readInt(json['id']);
    final nomorMeja = BudidayaModel._readInt(json['nomor_meja']);
    final kapasitasLubang = BudidayaModel._readInt(json['kapasitas_lubang']);
    final status = json['status'];

    if (id == null ||
        nomorMeja == null ||
        kapasitasLubang == null ||
        status is! String) {
      throw const FormatException('Format data meja tanam tidak valid.');
    }

    return BudidayaMejaModel(
      id: id,
      nomorMeja: nomorMeja,
      kapasitasLubang: kapasitasLubang,
      status: status,
      createdAt: BudidayaModel._readDate(json['created_at']),
      updatedAt: BudidayaModel._readDate(json['updated_at']),
    );
  }
}
