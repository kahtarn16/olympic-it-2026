import 'package:olympic_it_project/core/question_level.dart';
import 'package:olympic_it_project/core/question_type.dart';
import 'package:olympic_it_project/dto/admin_manager/question/create_question_option_request.dart';

class CreateQuestionRequest {
  final String content;
  final QuestionType type;
  final QuestionLevel level;
  final String? answer;
  final int score;
  final int categoryId;
  final int? timeLimit;
  final String? imageUrl;
  final String? videoUrl;
  final List<CreateQuestionOptionRequest> options; 

  CreateQuestionRequest({
    required this.content,
    required this.type,
    required this.level,
    this.answer,
    required this.score,
    required this.timeLimit,
    required this.categoryId,
    this.imageUrl,
    this.videoUrl,
    required this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      "content": content,
      "type": type.name,
      "level": level.name,
      "answer": answer,
      "score": score,
      "timeLimit" : timeLimit,
      "categoryId": categoryId,
      "imageUrl": imageUrl,
      "videoUrl": videoUrl,
      "options": options.map((option) => option.toJson()).toList(),
    };
  }
}