import 'dart:convert';

import 'package:olympic_it_project/core/network/api_client.dart';
import 'package:olympic_it_project/features/auth/data/models/login/login_request.dart';
import 'package:olympic_it_project/features/auth/data/models/login/login_response.dart';

class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource(this.apiClient);

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await apiClient.post("auth/login", body: request.toJson());

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = jsonDecode(response.body);
        return LoginResponse.fromJson(jsonMap);
      } else {
        print("Server returned ${response.statusCode}: ${response.body}");
        throw Exception("Lỗi ${response.statusCode}: Không thể đăng nhập");
      }
    } catch (e) {
      print("Repository Error: $e");
      throw Exception("Repository Error: $e");
    }
  }
}
