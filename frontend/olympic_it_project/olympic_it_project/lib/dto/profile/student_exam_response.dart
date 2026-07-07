class StudentExamDetailResponse {
  final int id;
  final String name;
  final String status;
  final int totalQuestions;

  StudentExamDetailResponse({
    required this.id,
    required this.name,
    required this.status,
    required this.totalQuestions,
  });

  factory StudentExamDetailResponse.fromJson(Map<String, dynamic> json) {
    return StudentExamDetailResponse(
      id: json["id"],
      name: json["name"],
      status: json["status"],
      totalQuestions: json["totalQuestions"],
    );
  }
}