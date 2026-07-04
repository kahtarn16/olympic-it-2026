class UpdateQuestionOptionRequest {
  final String label;
  final String contentText;
  final String? imageUrl;
  final bool isCorrect;

  UpdateQuestionOptionRequest({
    required this.label,
    required this.contentText,
    this.imageUrl,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() {
    return {
      "label": label,
      "contentText": contentText,
      "imageUrl": imageUrl,
      "isCorrect": isCorrect,
    };
  }
}