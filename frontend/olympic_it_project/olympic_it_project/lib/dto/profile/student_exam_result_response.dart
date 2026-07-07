import 'package:olympic_it_project/dto/admin_manager/exam/leader_board_response.dart';

class StudentExamResultResponse {
  final int score;
  final int rank;
  final int totalParticipants;
  final List<LeaderBoardResponse> leaderboard;

  StudentExamResultResponse({
    required this.score,
    required this.rank,
    required this.totalParticipants,
    required this.leaderboard,
  });


  factory StudentExamResultResponse.fromJson(
      Map<String, dynamic> json,
  ) {

    return StudentExamResultResponse(

      score: json['score'] ?? 0,

      rank: json['rank'] ?? 0,

      totalParticipants:
          json['totalParticipants'] ?? 0,

      leaderboard:
          (json['leaderboard'] as List<dynamic>? ?? [])
              .map(
                (e) => LeaderBoardResponse.fromJson(
                  e as Map<String,dynamic>,
                ),
              )
              .toList(),

    );
  }
}