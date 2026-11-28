import 'package:flutter_test/flutter_test.dart';
import 'package:sipentar/models/panen/panen_model.dart';

void main() {
  group('PanenModel', () {
    final responseJson = <String, dynamic>{
      'id': 25,
      'budidaya_id': 12,
      'tanggal_panen': '2026-11-28',
      'berat_kg': '2.75',
      'status': 'selesai',
      'budidaya': <String, dynamic>{
        'id': 12,
        'user_id': 3,
        'meja_id': 4,
        'tanggal_semai': '2026-10-01',
        'jumlah_tanaman': 24,
        'status': 'selesai',
        'hss': 58,
        'user': <String, dynamic>{
          'id': 3,
          'nama': 'Pemilik Kebun',
          'username': 'pemilik',
          'role': 'pemilik',
        },
        'meja': <String, dynamic>{
          'id': 4,
          'nomor_meja': 2,
          'kapasitas_lubang': 32,
          'status': 'terisi',
        },
      },
      'created_at': '2026-11-28T08:00:00.000000Z',
      'updated_at': '2026-11-28T08:00:00.000000Z',
    };

    test('membaca detail panen beserta relasi budidaya', () {
      final model = PanenModel.fromJson(responseJson);

      expect(model.id, 25);
      expect(model.budidayaId, 12);
      expect(model.tanggalPanen, DateTime(2026, 11, 28));
      expect(model.beratKg, 2.75);
      expect(model.status, PanenModel.statusSelesai);
      expect(model.budidaya?.mejaId, 4);
      expect(model.budidaya?.meja?.nomorMeja, 2);
      expect(model.budidaya?.jumlahTanaman, 24);
    });

    test('membaca berat null untuk panen terjadwal', () {
      final json = Map<String, dynamic>.from(responseJson)
        ..['status'] = PanenModel.statusTerjadwal
        ..['berat_kg'] = null;

      final model = PanenModel.fromJson(json);

      expect(model.status, PanenModel.statusTerjadwal);
      expect(model.beratKg, isNull);
    });

    test('menghasilkan payload hanya dengan field yang diterima API', () {
      final model = PanenModel(
        id: 1,
        budidayaId: 12,
        tanggalPanen: DateTime(2026, 11, 28),
        beratKg: 1.25,
        status: PanenModel.statusSelesai,
      );

      expect(model.toRequestJson(), <String, dynamic>{
        'budidaya_id': 12,
        'tanggal_panen': '2026-11-28',
        'berat_kg': 1.25,
        'status': 'selesai',
      });
    });

    test('menolak response tanpa field wajib', () {
      expect(
        () => PanenModel.fromJson(<String, dynamic>{'id': 1}),
        throwsFormatException,
      );
    });
  });

  group('Validasi berat panen', () {
    test('menerima angka finite minimal 0,01 kg', () {
      expect(PanenModel.isValidBeratKg(0.01), isTrue);
      expect(PanenModel.isValidBeratKg(0.5), isTrue);
    });

    test('menolak null, nol, negatif, NaN, dan Infinity', () {
      expect(PanenModel.isValidBeratKg(null), isFalse);
      expect(PanenModel.isValidBeratKg(0), isFalse);
      expect(PanenModel.isValidBeratKg(-1), isFalse);
      expect(PanenModel.isValidBeratKg(double.nan), isFalse);
      expect(PanenModel.isValidBeratKg(double.infinity), isFalse);
    });
  });
}
