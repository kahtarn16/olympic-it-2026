class CreateClassRequest {
  final String className;
  final int academicYearId;

  CreateClassRequest({
    required this.className,
    required this.academicYearId,
  });

  Map<String, dynamic> toJson() {
    return {
      "className": className,
      "academicYearId": academicYearId,
    };
  }
}