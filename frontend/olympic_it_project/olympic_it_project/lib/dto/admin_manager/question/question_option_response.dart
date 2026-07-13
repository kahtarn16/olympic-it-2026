class QuestionOptionResponse {
  final int id;
  final String label;
  final String contentText;
  final String? imageUrl;
  final bool isCorrect;

  QuestionOptionResponse({
    required this.id,
    required this.label,
    required this.contentText,
    this.imageUrl,
    required this.isCorrect,
  });

  factory QuestionOptionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionOptionResponse(
      id: json["id"],
      label: json["label"],
      contentText: json["contentText"],
      imageUrl: json["imageUrl"],
      isCorrect: json["isCorrect"],
    );
  }
}