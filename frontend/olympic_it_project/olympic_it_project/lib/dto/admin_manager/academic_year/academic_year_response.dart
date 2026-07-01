class AcademicYearResponse {
  final int id;
  final String yearName;

  AcademicYearResponse({
    required this.id,
    required this.yearName,
  });

  factory AcademicYearResponse.fromJson(Map<String, dynamic> json) {
    return AcademicYearResponse(
      id: json["id"],
      yearName: json["yearName"],
    );
  }
}