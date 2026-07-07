class LeaderBoardResponse {
  final int rank;
  final int userId;
  final String name;
  final int score;

  LeaderBoardResponse({
    required this.rank,
    required this.userId,
    required this.name,
    required this.score,
  });

  factory LeaderBoardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderBoardResponse(
      rank: json["rank"],
      userId: json["userId"],
      name: json["name"],
      score: json["score"],
    );
  }
}