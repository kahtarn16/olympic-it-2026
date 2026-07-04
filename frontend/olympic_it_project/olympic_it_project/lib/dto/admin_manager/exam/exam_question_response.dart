class ExamQuestionResponse {
  final int id;
  final int examId;
  final int questionId;
  final int orderIndex;
  final String questionContent;
  final int questionScore;
  final String questionType;

  ExamQuestionResponse({
    required this.id,
    required this.examId,
    required this.questionId,
    required this.orderIndex,
    required this.questionContent,
    required this.questionScore,
    required this.questionType,
  });

  factory ExamQuestionResponse.fromJson(Map<String, dynamic> json) {
    return ExamQuestionResponse(
      id: json['id'],
      examId: json['exam']?['id'] ?? 0,
      questionId: json['question']?['id'] ?? 0,
      orderIndex: json['orderIndex'] ?? 0,
      questionContent: json['question']?['content'] ?? '',
      questionScore: json['question']?['score'] ?? 0,
      questionType: json['question']?['type'] ?? '',
    );
  }
}
