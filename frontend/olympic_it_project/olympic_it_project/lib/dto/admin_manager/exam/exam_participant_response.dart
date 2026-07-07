class ExamParticipantResponse {
  final int id;
  final int userId;
  final String fullName;
  final String className;
  final String status;
  final int score;

  ExamParticipantResponse({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.className,
    required this.status,
    required this.score,
  });

  factory ExamParticipantResponse.fromJson(Map<String, dynamic> json) {
    return ExamParticipantResponse(
      id: json['id'],
      userId: json['userId'],
      fullName: json['fullName'] ?? '',
      className: json['className'] ?? '',
      status: json['status']?.toString() ?? '',
      score: json['score'] ?? 0,
    );
  }
}