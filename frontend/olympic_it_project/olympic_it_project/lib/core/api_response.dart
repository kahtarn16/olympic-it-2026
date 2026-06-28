class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse<T>(
      code: json['code'] ?? 0,
      message: json['message'] ?? 'Có lỗi xảy ra',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}