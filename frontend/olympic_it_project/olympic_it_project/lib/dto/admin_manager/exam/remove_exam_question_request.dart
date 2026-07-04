class RemoveExamQuestionRequest {
  final int examId;
  final int questionId;

  RemoveExamQuestionRequest({
    required this.examId,
    required this.questionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'examId': examId,
      'questionId': questionId,
    };
  }
}
