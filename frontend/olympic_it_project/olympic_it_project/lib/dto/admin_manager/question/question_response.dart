import 'package:olympic_it_project/core/question_level.dart';
import 'package:olympic_it_project/core/question_type.dart';

class QuestionResponse {
  final int id;
  final String content;
  final QuestionType type;
  final QuestionLevel level;
  final int score;
  final String? imageUrl;
  final String? videoUrl;
  final int? categoryId;
  final int timeLimit;
  final String? categoryName;

  QuestionResponse({
    required this.id,
    required this.content,
    required this.type,
    required this.level,
    required this.score,
    this.imageUrl,
    this.videoUrl,
    this.categoryId,
    required this.timeLimit,
    this.categoryName,
  });

  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionResponse(
      id: json["id"],
      content: json["content"],
      type: QuestionType.values.firstWhere((e) => e.name == json["type"]),
      level: QuestionLevel.values.firstWhere((e) => e.name == json["level"]),
      timeLimit: json["timeLimit"],
      score: json["score"],
      imageUrl: json["imageUrl"],
      videoUrl: json["videoUrl"],
      categoryId: json["categoryId"], 
      categoryName: json["categoryName"],
    );
  }
}