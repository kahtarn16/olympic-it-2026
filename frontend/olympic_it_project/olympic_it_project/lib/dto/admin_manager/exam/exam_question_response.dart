import 'package:olympic_it_project/dto/admin_manager/question/question_detail_response.dart';

class ExamQuestionResponse {
  final int orderIndex;
  final QuestionDetailResponse question;

  ExamQuestionResponse({
    required this.orderIndex,
    required this.question,
  });

  factory ExamQuestionResponse.fromJson(Map<String, dynamic> json) {
    return ExamQuestionResponse(
      orderIndex: json['orderIndex'],
      question: QuestionDetailResponse.fromJson(json['question']),
    );
  }
}