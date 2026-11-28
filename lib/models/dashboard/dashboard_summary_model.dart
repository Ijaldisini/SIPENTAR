import '../auth/user_model.dart';
import '../budidaya/budidaya_model.dart';
import '../panen/panen_model.dart';
import '../transaksi_keuangan/laporan_keuangan_model.dart';

/// Ringkasan gabungan untuk kartu-kartu Beranda SIPENTAR.
///
/// Model ini bukan representasi satu response endpoint `/dashboard` karena
/// backend belum menyediakan endpoint agregasi tersebut. DashboardService
/// membentuk model ini dari response endpoint masing-masing modul.
///
/// Bagian keuangan dan karyawan bersifat nullable karena hanya dapat dimuat
/// oleh role `pemilik`. Nilai null berarti bagian itu tidak tersedia/belum
/// dimuat, sedangkan angka nol berarti API memang mengembalikan nilai nol.
class DashboardSummaryModel {
  final DateTime tanggalReferensi;
  final DashboardBudidayaSummary? budidaya;
  final DashboardKeuanganSummary? keuangan;
  final DashboardStokSummary? stok;
  final DashboardKesehatanSummary? kesehatan;
  final DashboardKaryawanSummary? karyawan;

  const DashboardSummaryModel({
    required this.tanggalReferensi,
    this.budidaya,
    this.keuangan,
    this.stok,
    this.kesehatan,
    this.karyawan,
  });

  /// Jumlah hari menuju jadwal panen terdekat terhadap tanggal referensi.
  /// Null berarti belum ada jadwal panen berikutnya.
  int? get hariMenujuPanen {
    final panen = budidaya?.panenBerikut;
    if (panen == null) return null;

    final today = DateTime(
      tanggalReferensi.year,
      tanggalReferensi.month,
      tanggalReferensi.day,
    );
    final target = DateTime(
      panen.tanggalPanen.year,
      panen.tanggalPanen.month,
      panen.tanggalPanen.day,
    );

    return target.difference(today).inDays;
  }

  /// Menyalin ringkasan sambil mempertahankan bagian yang tidak diganti.
  /// Gunakan flag `clear...` bila sebuah bagian perlu diatur menjadi null.
  DashboardSummaryModel copyWith({
    DateTime? tanggalReferensi,
    DashboardBudidayaSummary? budidaya,
    DashboardKeuanganSummary? keuangan,
    DashboardStokSummary? stok,
    DashboardKesehatanSummary? kesehatan,
    DashboardKaryawanSummary? karyawan,
    bool clearBudidaya = false,
    bool clearKeuangan = false,
    bool clearStok = false,
    bool clearKesehatan = false,
    bool clearKaryawan = false,
  }) {
    return DashboardSummaryModel(
      tanggalReferensi: tanggalReferensi ?? this.tanggalReferensi,
      budidaya: clearBudidaya ? null : (budidaya ?? this.budidaya),
      keuangan: clearKeuangan ? null : (keuangan ?? this.keuangan),
      stok: clearStok ? null : (stok ?? this.stok),
      kesehatan: clearKesehatan ? null : (kesehatan ?? this.kesehatan),
      karyawan: clearKaryawan ? null : (karyawan ?? this.karyawan),
    );
  }
}

/// Ringkasan kartu Budidaya berdasarkan GET /budidaya dan GET /panen.
class DashboardBudidayaSummary {
  /// Satu budidaya yang dipilih service untuk ditonjolkan pada kartu Beranda.
  /// Null berarti backend belum memiliki budidaya berstatus `berjalan`.
  final BudidayaModel? budidayaUtama;

  /// Jumlah seluruh budidaya berstatus `berjalan` dari metadata pagination.
  final int totalBudidayaBerjalan;

  /// Jadwal terdekat yang belum lewat dan cocok dengan budidaya aktif.
  /// Null berarti belum ada jadwal panen berikutnya.
  final PanenModel? panenBerikut;

  const DashboardBudidayaSummary({
    required this.budidayaUtama,
    required this.totalBudidayaBerjalan,
    required this.panenBerikut,
  }) : assert(totalBudidayaBerjalan >= 0);

  int? get hss => budidayaUtama?.hss;

  int? get jumlahTanaman => budidayaUtama?.jumlahTanaman;

  int? get nomorMeja => budidayaUtama?.meja?.nomorMeja;

  /// Label yang hanya menggunakan data tersedia dari backend.
  /// Backend tidak mempunyai field `nama_batch`.
  String? get labelBudidaya {
    final item = budidayaUtama;
    if (item == null) return null;

    final nomor = item.meja?.nomorMeja;
    if (nomor == null) return 'Budidaya #${item.id}';

    return 'Meja ${nomor.toString().padLeft(2, '0')} • ${item.jumlahTanaman} tanaman';
  }
}

/// Ringkasan kartu Keuangan dari GET /keuangan/laporan.
///
/// Seluruh angka adalah agregat periode yang dilaporkan API. `selisih` bukan
/// saldo kumulatif sepanjang waktu.
class DashboardKeuanganSummary {
  final LaporanKeuanganModel laporan;

  const DashboardKeuanganSummary({required this.laporan});

  double get selisihPeriode => laporan.selisih;

  double get totalPemasukan => laporan.totalPemasukan;

  double get totalPengeluaran => laporan.totalPengeluaran;

  DateTime get tanggalMulai => laporan.tanggalMulai;

  DateTime get tanggalAkhir => laporan.tanggalAkhir;
}

/// Ringkasan kartu Stok dari GET /stok dan GET /notifikasi.
class DashboardStokSummary {
  /// Jumlah jenis barang dari `data.meta.total` endpoint `/stok`.
  final int totalJenisBarang;

  /// Jumlah item dari response endpoint `/notifikasi`.
  final int totalStokHampirHabis;

  const DashboardStokSummary({
    required this.totalJenisBarang,
    required this.totalStokHampirHabis,
  }) : assert(totalJenisBarang >= 0),
       assert(totalStokHampirHabis >= 0),
       assert(totalStokHampirHabis <= totalJenisBarang);

  int get totalStokAman => totalJenisBarang - totalStokHampirHabis;
}

/// Ringkasan kartu Kesehatan dari GET /diagnosis untuk tanggal referensi.
///
/// Kategori `perluPantau` berarti semua hasil selain `sehat`; backend tidak
/// mengirim kategori terpisah bernama "perlu pantau".
class DashboardKesehatanSummary {
  final int totalPemeriksaan;
  final int totalNormal;
  final int totalPerluPantau;

  const DashboardKesehatanSummary({
    required this.totalPemeriksaan,
    required this.totalNormal,
    required this.totalPerluPantau,
  }) : assert(totalPemeriksaan >= 0),
       assert(totalNormal >= 0),
       assert(totalPerluPantau >= 0),
       assert(totalNormal + totalPerluPantau == totalPemeriksaan);
}

/// Ringkasan kartu Karyawan dari GET /karyawan (pemilik saja).
///
/// `karyawanPreview` digunakan untuk inisial avatar. Nilai total tetap diambil
/// dari metadata pagination, bukan dari panjang daftar preview.
class DashboardKaryawanSummary {
  final int totalKaryawan;
  final List<UserModel> karyawanPreview;

  DashboardKaryawanSummary({
    required this.totalKaryawan,
    required List<UserModel> karyawanPreview,
  }) : assert(totalKaryawan >= 0),
       assert(karyawanPreview.length <= totalKaryawan),
       karyawanPreview = List<UserModel>.unmodifiable(karyawanPreview);
}
