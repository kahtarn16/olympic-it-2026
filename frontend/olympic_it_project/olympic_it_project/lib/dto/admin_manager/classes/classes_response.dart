class ClassResponse {
  final int id;
  final String className;
  final int academicYearId;

  ClassResponse({
    required this.id,
    required this.className,
    required this.academicYearId,
  });

  factory ClassResponse.fromJson(Map<String, dynamic> json) {
    return ClassResponse(
      id: json["id"],
      className: json["className"],
      academicYearId: json["academicYearId"],
    );
  }
}