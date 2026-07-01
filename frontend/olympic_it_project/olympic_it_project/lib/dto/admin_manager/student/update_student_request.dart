class UpdateStudentRequest {
  final String username;
  final String email;
  final String fullName;
  final int classId;

  UpdateStudentRequest({
    required this.username,
    required this.email,
    required this.fullName,
    required this.classId,
  });

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "email": email,
      "fullName": fullName,
      "classId": classId,
    };
  }
}