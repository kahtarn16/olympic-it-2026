import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:olympic_it_project/core/config.dart';
import 'package:olympic_it_project/core/storage_token.dart';
import 'package:olympic_it_project/service/auth_service.dart';

dynamic safeDecode(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    final body = response.body.trim();
    return body.isNotEmpty ? jsonDecode(body) : null;
  }
  throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
}

class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  // Giữ lại để tương thích với code cũ đang gọi ApiClient.host (ví dụ ghép URL ảnh)
  static const String host = HOST;

  // Lấy domain backend tập trung từ config.dart, không hardcode nữa.
  // Khi đổi sang ngrok/emulator/IP LAN, chỉ cần sửa trong config.dart.
  final String _baseUrl = API_BASE;

  Uri _buildUri(String endpoint) {
    // Loại bỏ dấu gạch chéo ở đầu endpoint nếu có để tránh bị nhân đôi dấu //
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;

    return Uri.parse("$_baseUrl$normalizedEndpoint");
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
    print("ACCESS TOKEN = $token");
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      // Bỏ qua trang cảnh báo trung gian của ngrok free plan
      if (IS_USING_NGROK) 'ngrok-skip-browser-warning': 'true',
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

    print("LẦN 1 = ${response.statusCode}");

    if (response.statusCode == 401 && _shouldRefresh(endpoint)) {
      print("==== REFRESH ====");

      await AuthService().refreshTokens();

      print(
        "TOKEN SAU REFRESH = ${await StorageToken.instance.getAccessToken()}",
      );

      response = await retry();

      print("LẦN 2 = ${response.statusCode}");
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

  Future<http.Response> deleteWithBodyRaw(
    String endpoint,
    dynamic body,
  ) async => await http
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
    final request = http.MultipartRequest("POST", _buildUri(endpoint));

    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }
    if (IS_USING_NGROK) {
      request.headers["ngrok-skip-browser-warning"] = "true";
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
