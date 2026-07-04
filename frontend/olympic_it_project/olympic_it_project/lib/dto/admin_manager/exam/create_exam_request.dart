class CreateExamRequest {
  final String name;
  final int createdById;
  final bool shuffleOption;

  CreateExamRequest({
    required this.name,
    required this.createdById,
    required this.shuffleOption,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'createdById': createdById,
      'shuffleOption': shuffleOption,
    };
  }
}
