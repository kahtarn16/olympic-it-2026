import 'package:olympic_it_project/dto/admin_manager/exam/question_detail_dto.dart';

class ExamRestoreResponse {
  final String state;
  final int currentQuestionIndex;
  final int totalQuestions;
  final QuestionDetailDto? currentQuestion;
  final int remainingSeconds;

  ExamRestoreResponse({
    required this.state,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    this.currentQuestion,
    required this.remainingSeconds,
  });

  factory ExamRestoreResponse.fromJson(Map<String, dynamic> json) {
    return ExamRestoreResponse(
      state: json['state'] ?? "IDLE",

      currentQuestionIndex:
          json['currentQuestionIndex'] ?? 0,

      totalQuestions:
          json['totalQuestions'] ?? 0,

      currentQuestion:
          json['currentQuestion'] != null
              ? QuestionDetailDto.fromJson(
                  json['currentQuestion'],
                )
              : null,

      remainingSeconds:
          json['remainingSeconds'] ?? 0,
    );
  }
}