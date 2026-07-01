class UpdateClassRequest {
  final String className;
  final int academicYearId;

  UpdateClassRequest({
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