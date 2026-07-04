class ExamParticipantResponse {
  final int id;
  final int examId;
  final int userId;
  final String userFullName;
  final String status;
  final int score;
  final String invitedAt;

  ExamParticipantResponse({
    required this.id,
    required this.examId,
    required this.userId,
    required this.userFullName,
    required this.status,
    required this.score,
    required this.invitedAt,
  });

  factory ExamParticipantResponse.fromJson(Map<String, dynamic> json) {
  return ExamParticipantResponse(
    id: json['id'],
    examId: json['examId'] ?? 0, 
    userId: json['userId'] ?? 0,
    userFullName: json['fullName'] ?? '',
    status: json['status'] ?? '',
    score: json['score'] ?? 0,
    invitedAt: json['invitedAt'] ?? '',
  );
}
}
