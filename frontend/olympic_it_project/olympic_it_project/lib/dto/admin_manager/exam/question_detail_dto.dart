class QuestionDetailDto {
  final int id;
  final String content;
  final String type;
  final String level;
  final int score;
  final String? imageUrl;
  final String? videoUrl;
  final int? timeLimit;
  final String? category;
  final List<QuestionOptionDto> options;

  QuestionDetailDto({
    required this.id,
    required this.content,
    required this.type,
    required this.level,
    required this.score,
    this.imageUrl,
    this.videoUrl,
    this.timeLimit,
    this.category,
    required this.options,
  });

  factory QuestionDetailDto.fromJson(Map<String, dynamic> json) {
    return QuestionDetailDto(
      id: json["id"] ?? 0,
      content: json["content"] ?? "",
      type: json["type"] ?? "",
      level: json["level"] ?? "",
      score: json["score"] ?? 0,
      imageUrl: json["imageUrl"],
      videoUrl: json["videoUrl"],
      timeLimit: json["timeLimit"],
      category: json["category"],
      options: (json["options"] as List<dynamic>? ?? [])
          .map((e) => QuestionOptionDto.fromJson(e))
          .toList(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "content": content,
      "type": type,
      "level": level,
      "score": score,
      "imageUrl": imageUrl,
      "videoUrl": videoUrl,
      "timeLimit": timeLimit,
      "category": category,
      "options": options.map((e) => e.toJson()).toList(), // Tự động convert list options con
    };
  }
}

class QuestionOptionDto {
  final int id;
  final String label;
  final String contentText;
  final String? imageUrl;

  QuestionOptionDto({
    required this.id,
    required this.label,
    required this.contentText,
    this.imageUrl,
  });

  factory QuestionOptionDto.fromJson(Map<String, dynamic> json) {
    return QuestionOptionDto(
      id: json["id"] ?? 0,
      label: json["label"] ?? "",
      contentText: json["contentText"] ?? "",
      imageUrl: json["imageUrl"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "label": label,
      "contentText": contentText,
      "imageUrl": imageUrl,
    };
  }
}