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

class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException([this.message = "Phiên đăng nhập đã hết hạn"]);

  @override
  String toString() => message;
}

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

    if (oldRefreshToken == null) {
      await StorageToken.instance.deleteAll();
      throw SessionExpiredException();
    }

    final request = RefreshTokenRequest(refreshToken: oldRefreshToken);

    final response = await _api.postRaw("auth/refresh", request.toJson());

    late final dynamic jsonMap;
    try {
      jsonMap = jsonDecode(response.body);
    } catch (_) {
      await StorageToken.instance.deleteAll();
      throw SessionExpiredException();
    }

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
      throw SessionExpiredException(apiResponse.message);
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
    try {
      final response = await _api.post("auth/logout", {});

      if (response.body.trim().isNotEmpty) {
        try {
          final jsonMap = jsonDecode(response.body);
          final apiResponse = ApiResponse.fromJson(
            jsonMap,
            (data) => data?.toString() ?? "",
          );
          if (apiResponse.code != 200) {
            // Server không xác nhận logout thành công (token die, v.v.)
            // -> vẫn tiếp tục xoá token cục bộ ở finally, không throw.
          }
        } catch (_) {
          // Body không parse được -> bỏ qua, vẫn coi như logout cục bộ.
        }
      }
    } catch (_) {
      // Mất mạng / SessionExpiredException / bất kỳ lỗi nào từ ApiClient
      // -> không quan trọng, mục tiêu là luôn dọn session cục bộ.
    } finally {
      await StorageToken.instance.deleteAll();
    }
  }
}