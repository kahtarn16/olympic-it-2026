import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl = "http://10.0.2.2:8080/api/";

  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();
  factory ApiClient() => instance;

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = _getHeaders();

    // DEBUG: In ra để xem chính xác đang gửi gì lên
    print("--- DEBUG API CALL ---");
    print("URL: $url");
    print("HEADERS: $headers");
    print("BODY: ${jsonEncode(body)}");
    print("----------------------");

    return await http.post(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final url = Uri.parse(
      '$baseUrl$endpoint',
    ).replace(queryParameters: queryParams);
    return await http.get(url, headers: _getHeaders());
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    return await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
    );
  }

  Map<String, String> _getHeaders() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }
}
