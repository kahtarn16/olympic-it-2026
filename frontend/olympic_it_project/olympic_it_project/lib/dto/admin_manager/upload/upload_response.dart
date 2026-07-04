class UploadResponse {
  final String url;

  UploadResponse({required this.url});

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      url: json["url"] ?? "",
    );
  }
}