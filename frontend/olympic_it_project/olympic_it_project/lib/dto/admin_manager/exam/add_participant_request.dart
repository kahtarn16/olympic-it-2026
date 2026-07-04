class AddParticipantRequest {
  final int examId;
  final int userId;

  AddParticipantRequest({
    required this.examId,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'examId': examId,
      'userId': userId,
    };
  }
}
