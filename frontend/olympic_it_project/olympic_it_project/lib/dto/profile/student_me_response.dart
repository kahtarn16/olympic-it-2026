class StudentMeResponse {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String? className;
  final String? academicYear;

  StudentMeResponse({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    this.className,
    this.academicYear,
  });

  factory StudentMeResponse.fromJson(Map<String, dynamic> json) {
    return StudentMeResponse(
      id: json['id'],
      username: json['username'],
      fullName: json['fullName'],
      email: json['email'],
      className: json['className'],
      academicYear: json['academicYear'],
    );
  }
}