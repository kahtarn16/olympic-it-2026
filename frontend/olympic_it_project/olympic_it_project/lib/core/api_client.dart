import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // 💡 BẮT BUỘC: Vá lỗi thiếu import MediaType
import 'package:olympic_it_project/core/api_response.dart';
import 'package:olympic_it_project/core/storage_token.dart';
import 'package:olympic_it_project/service/auth_service.dart';

/// Decode API response body safely, tránh FormatException khi server trả về body rỗng.
dynamic safeDecode(http.Response response) {
  final body = response.body.trim();
  if (body.isEmpty) return null;
  return jsonDecode(body);
}

String safeErrorMessage(http.Response response) {
  final body = response.body.trim();
  if (body.isEmpty) {
    return 'Lỗi server: ${response.statusCode}';
  }

  try {
    final jsonMap = jsonDecode(body);
    if (jsonMap is Map<String, dynamic>) {
      return jsonMap['message']?.toString() ??
          jsonMap['error']?.toString() ??
          body;
    }
    return body;
  } catch (_) {
    return body;
  }
}

ApiResponse<T> decodeApiResponse<T>(http.Response response, T Function(dynamic) fromJsonT) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(safeErrorMessage(response));
  }

  final jsonMap = safeDecode(response);
  if (jsonMap == null) {
    throw Exception('Lỗi server: ${response.statusCode}');
  }

  return ApiResponse.fromJson(jsonMap, fromJsonT);
}

class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  static const String host = "http://10.0.2.2:8080";
  final String _baseUrl = "$host/api/";

  Uri _buildUri(String endpoint) {
    final normalizedEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse(_baseUrl).resolve(normalizedEndpoint);
  }

  bool _shouldRefresh(String endpoint) {
    const excludedEndpoints = {
      "auth/login",
      "auth/resend-otp",
      "auth/forgot-password",
      "auth/reset-password",
      "auth/refresh",
    };
    return !excludedEndpoints.contains(endpoint);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageToken.instance.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> postRaw(String endpoint, dynamic body) async =>
      await http
          .post(
            _buildUri(endpoint),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

  Future<http.Response> _retryOnUnauthorized(
    String endpoint,
    Future<http.Response> Function() request,
    Future<http.Response> Function() retry,
  ) async {
    var response = await request();
    if (response.statusCode == 401 && _shouldRefresh(endpoint)) {
      await AuthService().refreshTokens();
      response = await retry();
    }
    return response;
  }

  Future<http.Response> post(String endpoint, dynamic body) async {
    return await _retryOnUnauthorized(
      endpoint,
      () => postRaw(endpoint, body),
      () => postRaw(endpoint, body),
    );
  }

  Future<http.Response> getRaw(String endpoint) async => await http
      .get(_buildUri(endpoint), headers: await _getHeaders())
      .timeout(const Duration(seconds: 15));

  Future<http.Response> get(String endpoint) async {
    return await _retryOnUnauthorized(
      endpoint,
      () => getRaw(endpoint),
      () => getRaw(endpoint),
    );
  }

  Future<http.Response> putRaw(String endpoint, dynamic body) async =>
      await http
          .put(
            _buildUri(endpoint),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

  Future<http.Response> put(String endpoint, dynamic body) async {
    return await _retryOnUnauthorized(
      endpoint,
      () => putRaw(endpoint, body),
      () => putRaw(endpoint, body),
    );
  }

  Future<http.Response> deleteRaw(String endpoint) async => await http
      .delete(_buildUri(endpoint), headers: await _getHeaders())
      .timeout(const Duration(seconds: 15));

  Future<http.Response> deleteWithBodyRaw(String endpoint, dynamic body) async => await http
      .delete(
        _buildUri(endpoint),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 15));

  Future<http.Response> deleteWithBody(String endpoint, dynamic body) async {
    return await _retryOnUnauthorized(
      endpoint,
      () => deleteWithBodyRaw(endpoint, body),
      () => deleteWithBodyRaw(endpoint, body),
    );
  }

  Future<http.Response> delete(String endpoint) async {
    return await _retryOnUnauthorized(
      endpoint,
      () => deleteRaw(endpoint),
      () => deleteRaw(endpoint),
    );
  }

  Future<http.StreamedResponse> _retryMultipartOnUnauthorized(
    String endpoint,
    Future<http.StreamedResponse> Function() request,
    Future<http.StreamedResponse> Function() retry,
  ) async {
    var response = await request();
    if (response.statusCode == 401 && _shouldRefresh(endpoint)) {
      await AuthService().refreshTokens();
      response = await retry();
    }
    return response;
  }

  Future<http.StreamedResponse> uploadMultipartRaw(
    String endpoint,
    String field,
    String filePath,
  ) async {
    final token = await StorageToken.instance.getAccessToken();
    final request = http.MultipartRequest(
      "POST",
      _buildUri(endpoint),
    );

    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    final file = File(filePath);
    final fileName = file.path.split('/').last;
    final ext = fileName.split('.').last.toLowerCase();

    final contentType = (ext == "png" || ext == "jpg" || ext == "jpeg")
        ? "image/$ext"
        : "video/mp4";

    request.files.add(
      await http.MultipartFile.fromPath(
        field,
        filePath,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
    );

    return request.send();
  }

  Future<http.StreamedResponse> uploadMultipart(
    String endpoint,
    String field,
    String filePath,
  ) async {
    return await _retryMultipartOnUnauthorized(
      endpoint,
      () => uploadMultipartRaw(endpoint, field, filePath),
      () => uploadMultipartRaw(endpoint, field, filePath),
    );
  }
}
