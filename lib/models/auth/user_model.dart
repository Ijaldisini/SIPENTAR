class UserModel {
  final int id;
  final String nama;
  final String username;
  final String role;

  const UserModel({
    required this.id,
    required this.nama,
    required this.username,
    required this.role,
  });

  // Mengubah JSON menjadi UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];

    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    if (id == null) {
      throw const FormatException('ID pengguna tidak valid.');
    }

    final nama = json['nama'];
    final username = json['username'];
    final role = json['role'];

    if (nama is! String || username is! String || role is! String) {
      throw const FormatException('Format data pengguna tidak valid.');
    }

    return UserModel(id: id, nama: nama, username: username, role: role);
  }
}
