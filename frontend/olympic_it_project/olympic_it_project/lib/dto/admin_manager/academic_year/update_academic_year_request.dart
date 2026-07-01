class UpdateAcademicYearRequest {
  final String academicYearName;

  UpdateAcademicYearRequest({
    required this.academicYearName
  });

  Map<String, dynamic> toJson() {
    return {
      "academicYearName" : academicYearName
    };
  }
}