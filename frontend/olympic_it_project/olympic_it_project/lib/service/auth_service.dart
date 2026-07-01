import 'dart:convert';

import 'package:olympic_it_project/core/api_client.dart';
import 'package:olympic_it_project/core/api_response.dart';
import 'package:olympic_it_project/core/storage_token.dart';
import 'package:olympic_it_project/dto/auth/forgotpassword/forgot_password_request.dart';
import 'package:olympic_it_project/dto/auth/forgotpassword/resend_otp_request.dart';
import 'package:olympic_it_project/dto/auth/forgotpassword/reset_password_request.dart';
import 'package:olympic_it_project/dto/auth/login/login_request.dart';
import 'package:olympic_it_project/dto/auth/login/login_response.dart';
import 'package:olympic_it_project/dto/auth/refresh_token/refresh_token_request.dart';

class AuthService {
  final _api = ApiClient.instance;

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _api.postRaw("auth/login", request.toJson());
    final jsonMap = jsonDecode(response.body);

    final apiResponse = ApiResponse.fromJson(
      jsonMap,
      (data) => LoginResponse.fromJson(data),
    );

    if (apiResponse.code == 200 && apiResponse.data != null) {
      await StorageToken.instance.saveTokens(
        apiResponse.data!.accessToken,
        apiResponse.data!.refreshToken,
      );
      await StorageToken.instance.saveUserInfo(
        apiResponse.data!.userId,
        apiResponse.data!.roleName,
      );
      return apiResponse.data!;
    } else {
      throw Exception(apiResponse.message);
    }
  }

  Future<void> refreshTokens() async {
    final oldRefreshToken = await StorageToken.instance.getRefreshToken();
    if (oldRefreshToken == null) throw Exception("Không có refresh token");

    final request = RefreshTokenRequest(refreshToken: oldRefreshToken);
    final response = await _api.postRaw("auth/refresh", request.toJson());
    final jsonMap = jsonDecode(response.body);

    final apiResponse = ApiResponse<LoginResponse>.fromJson(
      jsonMap,
      (data) => LoginResponse.fromJson(data),
    );

    if (apiResponse.code == 200 && apiResponse.data != null) {
      await StorageToken.instance.saveTokens(
        apiResponse.data!.accessToken,
        apiResponse.data!.refreshToken,
      );
    } else {
      await StorageToken.instance.deleteAll();
      throw Exception(apiResponse.message ?? "Phiên làm việc đã hết hạn");
    }
  }

  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    final response = await _api.postRaw(
      'auth/forgot-password',
      request.toJson(),
    );
    final jsonMap = jsonDecode(response.body);
    final apiResponse = ApiResponse.fromJson(
      jsonMap,
      (data) => data?.toString() ?? "",
    );

    if (apiResponse.code != 200) {
      throw Exception(apiResponse.message);
    }
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    final response = await _api.postRaw(
      "auth/reset-password",
      request.toJson(),
    );
    final jsonMap = jsonDecode(response.body);
    final apiResponse = ApiResponse.fromJson(
      jsonMap,
      (data) => data?.toString() ?? "",
    );

    if (apiResponse.code != 200) {
      throw Exception(apiResponse.message);
    }
  }

  Future<void> resendOtp(ResendOtpRequest request) async {
    final response = await _api.postRaw("auth/resend-otp", request.toJson());
    final jsonMap = jsonDecode(response.body);
    final apiResponse = ApiResponse.fromJson(
      jsonMap,
      (data) => data?.toString() ?? "",
    );

    if (apiResponse.code != 200) {
      throw Exception(apiResponse.message);
    }
  }

  Future<void> logout() async {
    final response = await _api.post("auth/logout", {});

    final jsonMap = jsonDecode(response.body);

    final apiResponse = ApiResponse.fromJson(
      jsonMap,
      (data) => data?.toString() ?? "",
    );

    if (apiResponse.code == 200) {
      await StorageToken.instance.deleteAll();
    } else {
      throw Exception(apiResponse.message);
    }
  }
}
