class LeaderboardDto {
  final int rank;
  final int userId;
  final String name;
  final int score;

  LeaderboardDto({
    required this.rank,
    required this.userId,
    required this.name,
    required this.score,
  });

  factory LeaderboardDto.fromJson(Map<String, dynamic> json) {
    return LeaderboardDto(
      rank: json['rank'] ?? 0,
      userId: json['userId'] ?? 0,
      name: json['name'] ?? '',
      score: json['score'] ?? 0,
    );
  }
}