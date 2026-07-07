class SubmitAnswerResponse {
  final int questionIndex;
  final bool? isCorrect;
  final int currentScore;

  SubmitAnswerResponse({
    required this.questionIndex,
    this.isCorrect,
    required this.currentScore,
  });

  factory SubmitAnswerResponse.fromJson(Map<String, dynamic> json) {
    return SubmitAnswerResponse(
      questionIndex: json['questionIndex'] ?? 0,
      isCorrect: json['isCorrect'],
      currentScore: json['currentScore'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionIndex': questionIndex,
      'isCorrect': isCorrect,
      'currentScore': currentScore,
    };
  }
}