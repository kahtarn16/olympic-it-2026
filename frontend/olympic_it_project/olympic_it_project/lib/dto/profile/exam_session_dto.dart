import 'package:olympic_it_project/dto/admin_manager/exam/question_detail_dto.dart';

class ExamSessionDto {
  final String state;
  final int? currentQuestionIndex;
  final int totalQuestions;
  final QuestionDetailDto? currentQuestion;
  final int? questionDuration;
  final DateTime? endAt;
  final int remainingSeconds;
  final DateTime? currentQuestionStartedAt;
  final DateTime? currentQuestionEndAt;

  ExamSessionDto({
    required this.state,
    this.currentQuestionIndex,
    required this.totalQuestions,
    this.currentQuestion,
    this.questionDuration,
    this.endAt,
    required this.remainingSeconds,
    this.currentQuestionStartedAt,
    this.currentQuestionEndAt,
  });


  factory ExamSessionDto.fromJson(Map<String, dynamic> json) {

    return ExamSessionDto(
      state: json['state'] ?? "",

      currentQuestionIndex:
          json['currentQuestionIndex'],

      totalQuestions:
          json['totalQuestions'] ?? 0,

      currentQuestion:
          json['currentQuestion'] != null
              ? QuestionDetailDto.fromJson(
                  json['currentQuestion'],
                )
              : null,

      questionDuration:
          json['questionDuration'],

      endAt:
          json['endAt'] != null
              ? DateTime.parse(json['endAt'])
              : null,

      remainingSeconds:
          json['remainingSeconds'] ?? 0,

      currentQuestionStartedAt:
          json['currentQuestionStartedAt'] != null
              ? DateTime.parse(
                  json['currentQuestionStartedAt'],
                )
              : null,

      currentQuestionEndAt:
          json['currentQuestionEndAt'] != null
              ? DateTime.parse(
                  json['currentQuestionEndAt'],
                )
              : null,
    );
  }
}