class UpdateExamRequest {
  final String name;
  final bool shuffleOption;

  UpdateExamRequest({
    required this.name,
    required this.shuffleOption,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'shuffleOption': shuffleOption,
    };
  }
}
