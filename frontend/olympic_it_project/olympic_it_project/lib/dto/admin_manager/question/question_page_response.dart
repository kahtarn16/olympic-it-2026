import 'package:olympic_it_project/dto/admin_manager/question/question_response.dart';

class QuestionPageResponse {
  final List<QuestionResponse> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  QuestionPageResponse({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory QuestionPageResponse.fromJson(Map<String, dynamic> json) {
    return QuestionPageResponse(
      items: (json["items"] as List)
          .map((e) => QuestionResponse.fromJson(e))
          .toList(),
      page: json["page"],
      size: json["size"],
      totalElements: json["totalElements"],
      totalPages: json["totalPages"],
    );
  }
}