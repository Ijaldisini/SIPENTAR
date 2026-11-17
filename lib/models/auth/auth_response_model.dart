import 'user_model.dart';

class AuthResponseModel {
  final bool success;
  final String message;
  final UserModel? user;
  final String? token;
  final String? tokenType;
  final Map<String, dynamic>? errors;

  const AuthResponseModel({
    required this.success,
    required this.message,
    this.user,
    this.token,
    this.tokenType,
    this.errors,
  });

  // Mengubah JSON response menjadi AuthResponseModel
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    // Mengambil data utama
    final rawData = json['data'];

    final data = rawData is Map ? Map<String, dynamic>.from(rawData) : null;

    // Mengambil data pengguna
    final rawUser = data?['user'];

    final userJson = rawUser is Map ? Map<String, dynamic>.from(rawUser) : null;

    // Mengambil error jika tersedia
    final rawErrors = json['errors'];

    final errorData = rawErrors is Map
        ? Map<String, dynamic>.from(rawErrors)
        : null;

    return AuthResponseModel(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      user: userJson != null ? UserModel.fromJson(userJson) : null,
      token: data?['token']?.toString(),
      tokenType: data?['token_type']?.toString(),
      errors: errorData,
    );
  }
}
