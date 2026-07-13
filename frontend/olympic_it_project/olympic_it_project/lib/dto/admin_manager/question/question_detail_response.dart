import 'package:olympic_it_project/core/question_level.dart';
import 'package:olympic_it_project/core/question_type.dart';
import 'package:olympic_it_project/dto/admin_manager/question/question_option_response.dart';

class QuestionDetailResponse {
  final int id;
  final String content;
  final String? answer;
  final int score;
  final String? imageUrl;
  final String? videoUrl;
  final QuestionType type;
  final QuestionLevel level;
  final int? categoryId;
  final String? categoryName;
  final List<QuestionOptionResponse> options;

  QuestionDetailResponse({
    required this.id,
    required this.content,
    required this.answer,
    required this.score,
    required this.imageUrl,
    required this.videoUrl,
    required this.type,
    required this.level,
    required this.categoryId,
    required this.categoryName,
    required this.options,
  });

  factory QuestionDetailResponse.fromJson(Map<String, dynamic> json) {
    return QuestionDetailResponse(
      id: json["id"],
      content: json["content"],
      answer: json["answer"],
      score: json["score"],
      imageUrl: json["imageUrl"],
      videoUrl: json["videoUrl"],
      type: QuestionType.values.firstWhere((e) => e.name == json["type"]),
      level: QuestionLevel.values.firstWhere((e) => e.name == json["level"]),
      categoryId: json["categoryId"],
      categoryName: json["categoryName"],
      options: (json["options"] as List? ?? [])
          .map((e) => QuestionOptionResponse.fromJson(e))
          .toList(),
    );
  }
}