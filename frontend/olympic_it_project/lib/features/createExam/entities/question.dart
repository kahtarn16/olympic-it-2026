import 'answer.dart';
import 'difficulty.dart';
import 'question_type.dart';
import 'dart:io';



class Question {
  File? imageFile;
  File? videoFile;

  int order;

  QuestionType type;

  String content;

  String? imageUrl;

  String? videoUrl;

  Difficulty difficulty;

  List<Answer> answers;

  List<String> correctAnswerIds;

  Question({
    required this.order,
    required this.type,
    required this.content,
    this.imageFile,
    this.videoFile,
    required this.difficulty,
    this.answers = const [],
    this.correctAnswerIds = const [],
  });
}