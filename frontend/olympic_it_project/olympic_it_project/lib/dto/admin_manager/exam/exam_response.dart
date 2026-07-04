class ExamResponse {
  final int id;
  final String name;
  final String status;
  final String createdBy;
  final String createdAt;
  final bool shuffleOption;

  ExamResponse({
    required this.id,
    required this.name,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.shuffleOption,
  });

  factory ExamResponse.fromJson(Map<String, dynamic> json) {
    return ExamResponse(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      createdBy: json['createdBy'],
      createdAt: json['createdAt'],
      shuffleOption: json['shuffleOption'] ?? false,
    );
  }
}