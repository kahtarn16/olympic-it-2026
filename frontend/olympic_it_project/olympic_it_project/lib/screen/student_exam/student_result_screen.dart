import 'package:flutter/material.dart';
import 'package:olympic_it_project/dto/profile/student_exam_result_response.dart';
import 'package:olympic_it_project/screen/home/user_home_screen.dart';
import 'package:olympic_it_project/service/profile_student_service.dart';

class ExamResultScreen extends StatefulWidget {
  final int examId;
  final StudentExamResultResponse? initialResult;
  final String? examName;

  const ExamResultScreen({
    super.key,
    required this.examId,
    this.initialResult,
    this.examName,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  final _profileService = ProfileStudentService();

  StudentExamResultResponse? result;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    if (widget.initialResult != null) {
      result = widget.initialResult;
      loading = false;
    } else {
      _loadResult();
    }
  }

  Future<void> _loadResult() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await _profileService.getExamResult(widget.examId);
      if (!mounted) return;
      setState(() {
        result = res;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.examName ?? "Kết quả bài thi"),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                "Không thể tải kết quả:\n$error",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadResult,
                child: const Text("Thử lại"),
              ),
            ],
          ),
        ),
      );
    }

    final r = result!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
          const SizedBox(height: 12),
          const Text(
            "Cuộc thi đã kết thúc!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text(
                        "Điểm của bạn",
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "${r.score}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  Column(
                    children: [
                      const Text(
                        "Xếp hạng",
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "${r.rank}/${r.totalParticipants}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Bảng xếp hạng",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          ...r.leaderboard.map((lb) {
            final isMe = lb.rank == r.rank;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue.withOpacity(0.1) : null,
                border: Border.all(
                  color: isMe ? Colors.blue : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      "#${lb.rank}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lb.name,
                      style: TextStyle(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    "${lb.score} điểm",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _goHome,
              icon: const Icon(Icons.home),
              label: const Text("Về màn hình chính"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}