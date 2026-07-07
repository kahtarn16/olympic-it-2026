import 'leaderboard_dto.dart';

class ExamResultResponse {
  final int score;
  final int rank;
  final int totalParticipants;
  final List<LeaderboardDto> leaderboard;

  ExamResultResponse({
    required this.score,
    required this.rank,
    required this.totalParticipants,
    required this.leaderboard,
  });

  factory ExamResultResponse.fromJson(Map<String, dynamic> json) {
    return ExamResultResponse(
      score: json['score'] ?? 0,
      rank: json['rank'] ?? 0,
      totalParticipants: json['totalParticipants'] ?? 0,
      leaderboard: (json['leaderboard'] as List? ?? [])
          .map((e) => LeaderboardDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}