class LoginResponse {
  final String token;

  LoginResponse({required this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // 1. Lấy giá trị từ key 'data'
    final data = json['data'];
    
    // 2. Chuyển đổi an toàn: Nếu data null hoặc không phải String, trả về chuỗi rỗng
    return LoginResponse(
      token: (data != null) ? data.toString() : "",
    );
  }
}