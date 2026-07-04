class AddExamQuestionRequest {
  final int examId;
  final int questionId;
  final int orderIndex;

  AddExamQuestionRequest({
    required this.examId,
    required this.questionId,
    required this.orderIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'examId': examId,
      'questionId': questionId,
      'orderIndex': orderIndex,
    };
  }
}
