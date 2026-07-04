import 'package:olympic_it_project/core/question_level.dart';
import 'package:olympic_it_project/core/question_type.dart';
import 'package:olympic_it_project/dto/admin_manager/question/create_question_option_request.dart';

class UpdateQuestionRequest {
  final String content;
  final QuestionType type;
  final QuestionLevel level;
  final String? answer;
  final int score;
  final int categoryId;
  final int timeLimit;
  final String? imageUrl;
  final String? videoUrl;
  final List<CreateQuestionOptionRequest>? options;

  UpdateQuestionRequest({
    required this.content,
    required this.type,
    required this.level,
    this.answer,
    required this.score,
    required this.categoryId,
    required this.timeLimit,
    this.imageUrl,
    this.videoUrl,
    this.options,
  });

  Map<String, dynamic> toJson() {
    final data = {
      "content": content,
      "type": type.name,
      "level": level.name,
      "answer": answer,
      "score": score,
      "categoryId": categoryId,
      "imageUrl": imageUrl,
      "videoUrl": videoUrl,
      "timeLimit": timeLimit,
    };

    if (options != null) {
      data["options"] = options!.map((option) => option.toJson()).toList();
    }

    return data;
  }
}