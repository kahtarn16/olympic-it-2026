class ExamSessionResponse {
  final String state;
  final int? currentQuestionIndex;
  final int? questionDuration;
  final bool? locked;

  ExamSessionResponse({
    required this.state,
    required this.currentQuestionIndex,
    required this.questionDuration,
    required this.locked,
  });

  factory ExamSessionResponse.fromJson(Map<String, dynamic> json) {
    return ExamSessionResponse(
      state: json["state"] ?? "WAITING",
      currentQuestionIndex: json["currentQuestionIndex"] != null 
          ? (json["currentQuestionIndex"] as num).toInt() 
          : null,
      questionDuration: json["questionDuration"] != null 
          ? (json["questionDuration"] as num).toInt() 
          : null,
      locked: json["locked"] as bool?,
    );
  }
}