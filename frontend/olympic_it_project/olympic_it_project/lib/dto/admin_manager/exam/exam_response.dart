class ExamResponse {
  final int id;
  final String name;
  final String status;
  final bool shuffleOption;
  final int createdById;
  final String createdBy;
  final String createdAt;

  ExamResponse({
    required this.id,
    required this.name,
    required this.status,
    required this.shuffleOption,
    required this.createdById,
    required this.createdBy,
    required this.createdAt,
  });

  factory ExamResponse.fromJson(Map<String, dynamic> json) {
    return ExamResponse(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      shuffleOption: json['shuffleOption'] ?? false,
      createdById: json['createdBy']?['id'] ?? 0,
      createdBy: json['createdBy']?['fullName'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
