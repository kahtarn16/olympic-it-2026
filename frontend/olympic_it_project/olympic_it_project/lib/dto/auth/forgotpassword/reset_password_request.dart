class ResetPasswordRequest {
  final String email;
  final String otpCode;
  final String newPassword;

  ResetPasswordRequest({
    required this.email,
    required this.otpCode,
    required this.newPassword
  });

  Map<String, dynamic> toJson() {
    return {
      "email" : email,
      "otpCode" : otpCode,
      "newPassword" : newPassword
    };
  }
}