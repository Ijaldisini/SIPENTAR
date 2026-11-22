import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client})
      : _client = client ?? http.Client();

  Uri _buildUri(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) {
    final baseUri = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint',
    );

    if (queryParameters == null || queryParameters.isEmpty) {
      return baseUri;
    }

    return baseUri.replace(
      queryParameters: {
        ...baseUri.queryParameters,
        ...queryParameters,
      },
    );
  }

  Map<String, String> _buildHeaders({
    String? token,
    bool hasBody = false,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (hasBody) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    return headers;
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    final uri = _buildUri(
      endpoint,
      queryParameters: queryParameters,
    );

    return await _client
        .get(
          uri,
          headers: _buildHeaders(token: token),
        )
        .timeout(ApiConfig.connectionTimeout);
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    final uri = _buildUri(
      endpoint,
      queryParameters: queryParameters,
    );

    return await _client
        .post(
          uri,
          headers: _buildHeaders(
            token: token,
            hasBody: true,
          ),
          body: jsonEncode(body ?? {}),
        )
        .timeout(ApiConfig.connectionTimeout);
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    final uri = _buildUri(
      endpoint,
      queryParameters: queryParameters,
    );

    return await _client
        .put(
          uri,
          headers: _buildHeaders(
            token: token,
            hasBody: true,
          ),
          body: jsonEncode(body ?? {}),
        )
        .timeout(ApiConfig.connectionTimeout);
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    final uri = _buildUri(
      endpoint,
      queryParameters: queryParameters,
    );

    return await _client
        .delete(
          uri,
          headers: _buildHeaders(
            token: token,
            hasBody: body != null,
          ),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(ApiConfig.connectionTimeout);
  }

  void dispose() {
    _client.close();
  }
}
