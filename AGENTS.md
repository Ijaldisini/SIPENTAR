# Flutter Application — SIPENTAR Frontend

Panduan ini berlaku untuk repository Flutter frontend SIPENTAR:

- Repository: https://github.com/Ijaldisini/SIPENTAR.git
- Backend terpisah: https://github.com/farhanzsani/sipentar-core-web.git
- Framework frontend: Flutter
- Bahasa: Dart
- Arsitektur yang digunakan: MVC (Model–View–Controller), dengan Service sebagai lapisan komunikasi API dan `core` untuk infrastruktur bersama.

Ikuti seluruh instruksi ini sebelum dan selama mengubah kode pada repository frontend.

## Prerequisites

Verifikasi Flutter SDK, Dart SDK, dan perangkat pengembangan tersedia:

```sh
flutter --version
dart --version
flutter doctor -v
```

Jika `flutter` atau `dart` tidak tersedia:

1. Identifikasi sistem operasi yang digunakan.
2. Ikuti panduan instalasi resmi Flutter: https://docs.flutter.dev/get-started/install
3. Pastikan Flutter SDK sudah masuk ke `PATH`.
4. Tutup dan buka kembali terminal setelah mengubah `PATH`.
5. Jalankan ulang perintah verifikasi di atas.

Jangan menjalankan perintah instalasi PHP, Composer, Laravel Boost, atau `php artisan` pada repository frontend ini. Perintah tersebut hanya berlaku pada repository backend Laravel.

## Project Setup

Jalankan perintah berikut dari root repository Flutter (direktori yang berisi `pubspec.yaml`):

```sh
flutter pub get
flutter doctor
flutter analyze
flutter test
```

Catatan:

- Jika folder `test/` belum berisi pengujian, catat kondisi tersebut; jangan mengklaim test suite sudah mencakup fitur tertentu.
- Jangan menjalankan `flutter pub upgrade --major-versions` tanpa kebutuhan dan persetujuan karena dapat mengubah banyak versi dependency.
- Jangan menghapus atau mengganti dependency yang sudah digunakan tanpa memeriksa seluruh pemakaiannya.
- Sebelum mengubah file, periksa `pubspec.yaml`, struktur folder aktual, dan status Git.

## Agent Workflow

Sebelum membuat perubahan:

1. Baca `AGENTS.md` ini.
2. Periksa source code aktual pada branch dan working tree yang sedang digunakan.
3. Jalankan `git status --short` untuk mengetahui perubahan yang sudah ada.
4. Periksa file terkait dan pemanggilnya sebelum mengubah API, nama field, state, atau navigasi.
5. Untuk integrasi backend, periksa route, Controller, Resource, middleware, enum, OpenAPI, serta contoh response aktual dari repository backend. Jangan mengandalkan dokumentasi yang sudah diketahui dapat berbeda dari implementasi.

Saat mengerjakan fitur:

- Kerjakan secara bertahap dan fokus pada satu lapisan atau satu fitur dalam satu waktu.
- Jelaskan file yang dibuat/diubah, alasan perubahan, serta perintah pengujian.
- Setelah satu tahap, jalankan pemeriksaan dan tunggu hasilnya sebelum melanjutkan ke tahap lain.
- Jangan memberikan atau menulis ulang seluruh project sekaligus.
- Jangan mengklaim pekerjaan sudah selesai, diuji, di-commit, atau di-push jika hal tersebut belum benar-benar dilakukan.

## Architecture Guidelines

Pertahankan pemisahan tanggung jawab berikut:

### `core/`

Berisi infrastruktur lintas fitur, misalnya:

- Konfigurasi Base URL dan timeout.
- HTTP client bersama.
- Penyimpanan token dan utilitas sesi.

### `models/`

- Merepresentasikan struktur data yang diterima/dikirim API.
- Menyediakan parsing JSON seperti `fromJson` dan serialisasi jika diperlukan.
- Gunakan tipe data yang sesuai dengan response aktual.
- Tangani field nullable berdasarkan kontrak API; jangan menebak field yang tidak tersedia.
- Hindari memasukkan widget atau kode navigasi ke Model.

### `services/`

- Menangani HTTP request ke backend.
- Menggunakan `ApiClient` bersama.
- Menggunakan Bearer Token untuk endpoint yang memerlukan autentikasi.
- Mengubah response JSON menjadi Model.
- Menangani status HTTP dan format response secara konsisten.
- Tidak mengatur layout atau melakukan navigasi UI.

### `controllers/`

- Menggunakan `ChangeNotifier` untuk state dan logika fitur.
- Memanggil Service, bukan mengirim HTTP request langsung dari View.
- Menyediakan state loading, data, error, dan status lain yang relevan.
- Memanggil `notifyListeners()` setelah perubahan state yang perlu ditampilkan.
- Mengelola lifecycle dan `dispose()` dengan benar.

### `views/`

- Bertanggung jawab pada UI/UX, input pengguna, dan penyajian state.
- Tidak memanggil HTTP client atau mengakses endpoint secara langsung.
- Tidak menyimpan token secara langsung.
- Memanggil Controller untuk operasi fitur.
- Menjaga layout, warna, ukuran, aset, scroll, dan navigasi visual yang sudah disepakati.

## UI/UX Rules

Pertahankan desain SIPENTAR yang sudah dibuat dari Figma. Jangan merombak atau mengubah tampilan tanpa permintaan eksplisit.

Identitas desain yang telah digunakan:

- Warna utama: `#6E8649` (`Color(0xFF6E8649)`).
- Warna permukaan lembut: `#F1F5E9`.
- Warna teks utama: `#26351F`.
- Font: Inter melalui package `google_fonts`.
- Background autentikasi: `assets/images/background_welcome_page.png`.
- Logo splash menggunakan asset gambar yang tersedia pada folder `assets/images`.

Ketika mengintegrasikan API:

- Ganti sumber data dummy secara bertahap tanpa mengubah struktur layout.
- Pertahankan komponen reusable yang sudah ada.
- Pertahankan perilaku scroll dan bottom navigation.
- Tambahkan loading, empty state, dan error state dengan gaya visual yang konsisten.
- Jangan menghapus data dummy sampai penggantinya dari API sudah terhubung dan diuji.

## API and Backend Integration

Backend terpisah dan menggunakan Laravel API. Repository backend:

https://github.com/farhanzsani/sipentar-core-web.git

Base path API yang digunakan pada dokumentasi adalah `/api/v1`.

### API Client

- Gunakan HTTP client bersama dari `core/network`.
- Pertahankan dan gunakan method HTTP yang tersedia (`GET`, `POST`, `PUT`, serta `DELETE` hanya jika endpoint backend menyediakannya).
- Dukung query parameters untuk pencarian, filter, dan pagination jika endpoint mendukungnya.
- Gunakan `Accept: application/json`.
- Tambahkan `Content-Type: application/json` untuk request JSON.
- Sertakan `Authorization: Bearer <token>` untuk endpoint terlindungi.
- Terapkan timeout terpusat.
- Jangan menelan error koneksi atau parsing secara diam-diam.

### Base URL

Jangan mengunci alamat pengembangan pribadi ke source code production.

Contoh alamat lokal:

- Android Emulator: biasanya `http://10.0.2.2:8000/api/v1` untuk mengakses server pada komputer host.
- Android fisik: gunakan alamat IPv4 komputer yang menjalankan Laravel dan pastikan perangkat berada di jaringan yang dapat mengaksesnya.
- Production: gunakan domain backend dengan HTTPS.

Sebelum pengujian, pastikan Base URL yang digunakan cocok dengan perangkat dan environment.

### Authentication and Token

- Backend menggunakan Laravel Sanctum Personal Access Token berdasarkan implementasi yang telah diperiksa.
- Perlakukan token sebagai opaque Bearer Token; jangan melakukan decoding seolah-olah token JWT.
- Simpan token melalui `flutter_secure_storage`.
- Jangan mencetak token, password, atau kredensial ke console/log.
- Logout harus memanggil endpoint backend yang sesuai dan membersihkan token lokal sesuai hasil proses logout.
- Pemulihan sesi harus memvalidasi token melalui endpoint identitas pengguna yang benar-benar tersedia pada branch backend aktif.
- Jangan menganggap endpoint `/me` tersedia hanya karena pernah tercatat pada percakapan; verifikasi `routes/api.php` pada branch yang sedang diintegrasikan.

### API Contract Verification

Dokumentasi OpenAPI yang pernah diberikan memuat endpoint seperti:

- Authentication: `/auth/login`, `/auth/logout`.
- Budidaya: `/budidaya`, `/budidaya/{id}`.
- Karyawan: `/karyawan`, `/karyawan/{id}`.
- Keuangan: `/keuangan/hpp`, `/keuangan/alokasi-kas`, `/keuangan/laporan`.
- Meja Tanam: `/meja-tanam`.
- Notifikasi: `/notifikasi`.
- Panen: `/panen`, `/panen/{id}`.
- Penggunaan Operasional: `/penggunaan-operasional`.
- Profil: `/profil`.
- Stok: `/stok`, `/stok/{id}`.
- Transaksi Keuangan: `/transaksi-keuangan`, `/transaksi-keuangan/{id}`.

Daftar ini merupakan petunjuk awal, bukan jaminan kontrak terbaru. Selalu periksa OpenAPI dan implementasi backend sebelum membuat Service atau Model.

Beberapa ketidaksesuaian pernah ditemukan antara dokumentasi dan implementasi, antara lain:

- Role di dokumentasi pernah berbeda dari enum role backend.
- Dokumentasi pernah tidak mencantumkan endpoint sesi `/me` yang disebut ada pada route backend.
- Dokumentasi Bearer pernah menyebut JWT, sedangkan implementasi token menggunakan Sanctum.
- Sejumlah endpoint belum memiliki schema response JSON yang rinci.

Karena itu:

1. Periksa enum role, middleware, policy, Controller, dan Resource di backend.
2. Periksa route aktual melalui `php artisan route:list` pada repository backend jika tersedia.
3. Periksa/generate OpenAPI terbaru.
4. Minta contoh response aktual untuk endpoint yang schema-nya belum jelas.
5. Jangan menebak bentuk pagination, nama field, tipe angka, tanggal, nullable, atau wrapper `data`.
6. Catat ketidaksesuaian BE–FE dan minta tim backend menyepakati kontrak final.

### Role and Authorization

- Jangan mengunci nilai role berdasarkan contoh Swagger lama.
- Gunakan nilai role yang benar-benar dikembalikan backend.
- Hak akses UI harus konsisten dengan middleware/policy backend.
- Menyembunyikan tombol pada UI bukan pengganti otorisasi backend.
- Endpoint khusus pemilik harus tetap ditangani sebagai endpoint terlindungi oleh backend.

### Features Without a Confirmed Endpoint

- Jangan membuat request untuk fitur yang belum memiliki endpoint.
- Registrasi mobile belum boleh diasumsikan tersedia hanya karena Register View sudah ada.
- Dashboard belum tentu memiliki satu endpoint agregat; gabungkan data dari endpoint modul yang tersedia setelah kontraknya jelas.
- Diagnosis kesehatan selada tidak boleh diasumsikan tersedia sebelum endpoint dan response disediakan backend.
- Jika fitur belum didukung backend, tandai sebagai UI/dummy dan jelaskan keterbatasannya.

## Error Handling

Sesuaikan penanganan error dengan kontrak setiap endpoint. Kondisi yang perlu dipertimbangkan:

- `200` / `201`: request berhasil sesuai operasi.
- `401`: token tidak valid atau autentikasi gagal.
- `403`: pengguna tidak memiliki hak akses.
- `404`: resource atau endpoint tidak ditemukan.
- `422`: validasi request gagal.
- `429`: rate limit tercapai.
- `500` dan status server lain: kegagalan backend.
- Timeout, kegagalan jaringan, respons non-JSON, serta JSON dengan struktur yang tidak sesuai.

Jangan menganggap semua status non-2xx memiliki struktur body yang sama. Periksa response aktual sebelum melakukan parsing.

## Code Quality and Testing

Setelah perubahan kode:

```sh
dart format lib
flutter analyze
flutter test
```

Jika perubahan menyentuh integrasi API, lakukan pengujian tambahan:

- Request berhasil dan gagal.
- Token tersedia dan tidak tersedia.
- Respons 401/403/422 sesuai kontrak.
- Timeout dan koneksi gagal.
- Loading dan error state pada View.
- Navigasi serta regresi UI.

Jangan menyatakan semua test lulus bila perintah belum dijalankan atau hasilnya belum diperiksa.

## Git and Commit Rules

Sebelum commit:

```sh
git status --short
git diff --check
git diff
flutter analyze
```

- Jangan menghapus atau menimpa perubahan lokal pengguna yang belum di-commit.
- Jangan memasukkan `.env`, password, token, file credential, atau data pribadi.
- Jangan memasukkan alamat IP lokal sebagai konfigurasi production.
- Buat commit hanya setelah perubahan dan cakupannya diperiksa.
- Catat hash commit hanya setelah commit benar-benar dibuat.
- Jangan mengklaim perubahan sudah di-push sebelum push berhasil.

Contoh pesan commit (sesuaikan dengan perubahan aktual):

```text
docs: add Flutter agent guidelines
refactor(network): extend API client methods
feat(auth): add session restoration
feat(stock): integrate stock API
feat(finance): integrate finance API
```

## Working Style

- Gunakan Bahasa Indonesia untuk penjelasan kepada pengguna.
- Berikan instruksi bertahap, singkat, jelas, dan mudah diikuti.
- Jangan mengirim seluruh implementasi semua modul dalam satu balasan.
- Setelah satu tahap selesai, berhenti dan tunggu arahan pengguna sebelum melanjutkan.
- Sebutkan path file secara eksplisit.
- Berikan kode yang lengkap untuk file atau bagian yang diminta, tetapi jangan mengganti file lain yang tidak terkait.
- Jika ada informasi yang belum diketahui, periksa repository atau minta response API aktual; jangan mengarang.
- Saat memperbaiki analyzer, gunakan variabel dan tipe yang benar-benar tersedia di scope.

## Current Development Priorities

Urutan prioritas yang direkomendasikan:

1. Verifikasi kondisi aktual API Client dan konfigurasi Base URL.
2. Implementasikan session restoration menggunakan endpoint identitas pengguna yang telah diverifikasi.
3. Implementasikan logout dan pembersihan token.
4. Sinkronkan User Model dan role dengan kontrak backend final.
5. Integrasikan modul Stok: Model → Service → Controller → View.
6. Integrasikan modul Keuangan: transaksi, HPP, alokasi kas, dan laporan.
7. Ganti data dummy Dashboard dengan data endpoint yang tersedia.
8. Lanjutkan Budidaya, Panen, Meja Tanam, Penggunaan Operasional, Notifikasi, dan Karyawan.
9. Jalankan regression test pada seluruh navigasi dan UI yang sudah ada.

Sebelum memulai salah satu prioritas, verifikasi bahwa pekerjaan tersebut belum dikerjakan di branch aktif.
