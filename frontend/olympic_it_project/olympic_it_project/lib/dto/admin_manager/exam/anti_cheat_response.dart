class AntiCheatResponse {
  final int userId;
  final String fullName;
  final String type;
  final String createdAt;

  AntiCheatResponse({
    required this.userId,
    required this.fullName,
    required this.type,
    required this.createdAt,
  });

  factory AntiCheatResponse.fromJson(Map<String, dynamic> json) {
    return AntiCheatResponse(
      userId: json["userId"],
      fullName: json["fullName"],
      type: json["type"],
      createdAt: json["createdAt"],
    );
  }
}