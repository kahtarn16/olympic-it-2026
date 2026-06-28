import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:olympic_it_project/core/storage_token.dart';
import 'package:olympic_it_project/service/auth_service.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  final String _baseUrl = "http://10.0.2.2:8080/api/";

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

  Future<http.Response> postRaw(String endpoint, dynamic body) async {
    return await http
        .post(
          Uri.parse(_baseUrl + endpoint),
          headers: await _getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
  }

  Future<http.Response> post(String endpoint, dynamic body) async {
    var response = await postRaw(endpoint, body);

    if (response.statusCode == 401 && _shouldRefresh(endpoint)) {
      try {
        await AuthService().refreshTokens();

        response = await postRaw(endpoint, body);
      } catch (e) {
        rethrow;
      }
    }

    return response;
  }

  Future<http.Response> getRaw(String endpoint) async {
    return await http
        .get(Uri.parse(_baseUrl + endpoint), headers: await _getHeaders())
        .timeout(const Duration(seconds: 15));
  }

  Future<http.Response> get(String endpoint) async {
    var response = await getRaw(endpoint);

    if (response.statusCode == 401 && _shouldRefresh(endpoint)) {
      try {
        await AuthService().refreshTokens();

        response = await getRaw(endpoint);
      } catch (e) {
        rethrow;
      }
    }

    return response;
  }

  Future<http.Response> putRaw(String endpoint, dynamic body) async {
    return await http
        .put(
          Uri.parse(_baseUrl + endpoint),
          headers: await _getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
  }

  Future<http.Response> put(String endpoint, dynamic body) async {
    var response = await putRaw(endpoint, body);

    if (response.statusCode == 401 && _shouldRefresh(endpoint)) {
      try {
        await AuthService().refreshTokens();

        response = await putRaw(endpoint, body);
      } catch (e) {
        rethrow;
      }
    }

    return response;
  }

  Future<http.Response> deleteRaw(String endpoint) async {
    return await http
        .delete(
          Uri.parse(_baseUrl + endpoint),
          headers: await _getHeaders()
        )
        .timeout(const Duration(seconds: 15));
  }

  Future<http.Response> delete(String endpoint) async {
    var response = await deleteRaw(endpoint);

    if (response.statusCode == 401 && _shouldRefresh(endpoint)) {
      try {
        await AuthService().refreshTokens();

        response = await deleteRaw(endpoint);
      } catch (e) {
        rethrow;
      }
    }

    return response;
  }
}
