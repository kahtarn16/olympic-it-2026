class MyExamResponse {
  final int examId;
  final String examName;
  final String status;

  MyExamResponse({
    required this.examId,
    required this.examName,
    required this.status,
  });

  factory MyExamResponse.fromJson(Map<String, dynamic> json) {
    return MyExamResponse(
      examId: json['examId'],
      examName: json['examName'],
      status: json['status'],
    );
  }
}