import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:olympic_it_project/core/config.dart'; 
import 'package:olympic_it_project/core/storage_token.dart';
import 'package:olympic_it_project/service/auth_service.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  static const String host = HOST;
  final String _baseUrl = API_BASE;
  
  Future<void>? _refreshFuture;

  Future<void> _refreshOnce() {
    _refreshFuture ??= AuthService().refreshTokens().whenComplete(() {
      _refreshFuture = null;
    });
    return _refreshFuture!;
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
            Uri.parse(_baseUrl + endpoint),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

  Future<http.Response> post(String endpoint, dynamic body) async {
    var response = await postRaw(endpoint, body);
    if (response.statusCode == 401 && _shouldRefresh(endpoint)) {
      await _refreshOnce();
      response = await postRaw(endpoint, body);
    }
    return response;
  }

  Future<http.Response> getRaw(String endpoint) async => await http
      .get(Uri.parse(_baseUrl + endpoint), headers: await _getHeaders())
      .timeout(const Duration(seconds: 15));

  Future<http.Response> get(String endpoint) async {
    var response = await getRaw(endpoint);
    if (response.statusCode == 401 && _shouldRefresh(endpoint)) {
      await _refreshOnce();
      response = await getRaw(endpoint);
    }
    return response;
  }

  Future<http.Response> putRaw(String endpoint, dynamic body) async =>
      await http
          .put(
            Uri.parse(_baseUrl + endpoint),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

  Future<http.Response> put(String endpoint, dynamic body) async {
    var response = await putRaw(endpoint, body);
    if (response.statusCode == 401 && _shouldRefresh(endpoint)) {
      await _refreshOnce();
      response = await putRaw(endpoint, body);
    }
    return response;
  }

  Future<http.Response> deleteRaw(String endpoint) async => await http
      .delete(Uri.parse(_baseUrl + endpoint), headers: await _getHeaders())
      .timeout(const Duration(seconds: 15));

  Future<http.Response> delete(String endpoint) async {
    var response = await deleteRaw(endpoint);
    if (response.statusCode == 401 && _shouldRefresh(endpoint)) {
      await _refreshOnce();
      response = await deleteRaw(endpoint);
    }
    return response;
  }

  // ================= DELETE có body (cần cho các API xóa kèm dữ liệu) =================
  Future<http.Response> deleteWithBodyRaw(
    String endpoint,
    dynamic body,
  ) async => await http
      .delete(
        Uri.parse(_baseUrl + endpoint),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 15));

  Future<http.Response> deleteWithBody(String endpoint, dynamic body) async {
    var response = await deleteWithBodyRaw(endpoint, body);
    if (response.statusCode == 401 && _shouldRefresh(endpoint)) {
      await _refreshOnce();
      response = await deleteWithBodyRaw(endpoint, body);
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
      Uri.parse(_baseUrl + endpoint),
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
    var response = await uploadMultipartRaw(endpoint, field, filePath);

    if (response.statusCode == 401 && _shouldRefresh(endpoint)) {
      await _refreshOnce();
      response = await uploadMultipartRaw(endpoint, field, filePath);
    }
    return response;
  }
}

dynamic safeDecode(http.Response response) {
  if (response.body.trim().isEmpty) {
    return {
      "code": response.statusCode,
      "message": "Empty response body",
      "data": null,
    };
  }
  try {
    return jsonDecode(response.body);
  } catch (e) {
    return {
      "code": response.statusCode,
      "message": "Không thể phân tích phản hồi từ server",
      "data": null,
    };
  }
}