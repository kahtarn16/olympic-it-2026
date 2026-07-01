class StudentResponse {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final int classId;
  final String className;

  StudentResponse({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.classId,
    required this.className,
  });

  factory StudentResponse.fromJson(Map<String, dynamic> json) {
    return StudentResponse(
      id: json["id"] ?? 0,
      username: json["username"] ?? "",
      email: json["email"] ?? "",
      fullName: json["fullName"] ?? "",
      classId: json["classId"] ?? 0,
      className: json["className"] ?? "",
    );
  }
}