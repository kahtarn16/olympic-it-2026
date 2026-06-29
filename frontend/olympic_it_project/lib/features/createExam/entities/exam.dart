import 'question.dart';

class Exam {
  final String id;

  String title;

  String description;

  String subject;

  String target;

  /// STEP 3

  int duration;

  int totalScore;

  bool showResultAfterSubmit;

  bool shuffleQuestions;

  int maxAttempts;

  List<Question> questions;

  Exam({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.target,

    this.duration = 60,

    this.totalScore = 100,

    this.showResultAfterSubmit = true,

    this.shuffleQuestions = false,

    this.maxAttempts = 1,

    this.questions = const [],
  });
}