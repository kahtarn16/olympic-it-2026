import 'package:olympic_it_project/dto/admin_manager/exam/exam_participant_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_question_response.dart';

class ExamDetailsResponse {
  final int id;
  final String name;
  final String status;
  final bool shuffleOption;
  final String createdBy;
  final String createdAt;
  final List<ExamQuestionResponse> questions;
  final List<ExamParticipantResponse> participants;

  ExamDetailsResponse({
    required this.id,
    required this.name,
    required this.status,
    required this.shuffleOption,
    required this.createdBy,
    required this.createdAt,
    required this.questions,
    required this.participants,
  });

  factory ExamDetailsResponse.fromJson(Map<String, dynamic> json) {
    return ExamDetailsResponse(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      shuffleOption: json['shuffleOption'] ?? false,
      createdBy: json['createdBy'],
      createdAt: json['createdAt'],

      questions: (json['questions'] as List? ?? [])
          .map((e) => ExamQuestionResponse.fromJson(e))
          .toList(),

      participants: (json['participants'] as List? ?? [])
          .map((e) => ExamParticipantResponse.fromJson(e))
          .toList(),
    );
  }
}
