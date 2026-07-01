class CreateStudentRequest {
  final String username;
  final String password;
  final String email;
  final String fullName;
  final int classId;

  CreateStudentRequest({
    required this.username,
    required this.password,
    required this.email,
    required this.fullName,
    required this.classId,
  });

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "password": password,
      "email": email,
      "fullName": fullName,
      "classId": classId,
    };
  }
}