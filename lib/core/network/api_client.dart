import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  final http.Client _client = http.Client();

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    debugPrint('URL API FLUTTER: $uri');

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      return await _client
          .post(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(ApiConfig.connectionTimeout);
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
