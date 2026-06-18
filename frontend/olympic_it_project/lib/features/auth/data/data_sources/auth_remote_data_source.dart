import 'dart:convert';

import 'package:olympic_it_project/core/network/api_client.dart';
import 'package:olympic_it_project/features/auth/data/models/login/login_request.dart';
import 'package:olympic_it_project/features/auth/data/models/login/login_response.dart';

class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource(this.apiClient);

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await apiClient.post("login", body: request.toJson());

    if(response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);

      return LoginResponse.fromJson(jsonMap);
    } else {
      throw Exception("Đăng nhập thất bại với mã lỗi: ${response.statusCode}");
    }
  }
}