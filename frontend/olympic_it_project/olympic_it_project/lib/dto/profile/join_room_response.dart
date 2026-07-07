class JoinRoomResponse {
  final int examId;
  final String examName;
  final String state;
  final String message;

  JoinRoomResponse({
    required this.examId,
    required this.examName,
    required this.state,
    required this.message,
  });


  factory JoinRoomResponse.fromJson(Map<String, dynamic> json) {
    return JoinRoomResponse(
      examId: json['examId'],
      examName: json['examName'],
      state: json['state'],
      message: json['message'],
    );
  }
}