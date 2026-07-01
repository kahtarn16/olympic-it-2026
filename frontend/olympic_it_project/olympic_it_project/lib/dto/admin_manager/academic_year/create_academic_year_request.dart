class CreateAcademicYearRequest {
  final String academicYearName;

  CreateAcademicYearRequest({
    required this.academicYearName
  });

  Map<String, dynamic> toJson() {
    return {
      "academicYearName" : academicYearName
    };
  }
}