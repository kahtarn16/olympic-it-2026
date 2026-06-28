class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String roleName;
  final int userId;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.roleName,
    required this.userId
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(accessToken: json["accessToken"] ?? "",
    refreshToken: json["refreshToken"] ?? "",
    roleName: json["roleName"] ?? "",
    userId: json["userId"] ?? 0
    );
  }
}