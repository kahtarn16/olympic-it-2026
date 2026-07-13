import 'package:flutter/material.dart';
import 'package:olympic_it_project/dto/profile/student_exam_response.dart';
import 'package:olympic_it_project/screen/student_exam/student_exam_screen.dart';
import 'package:olympic_it_project/screen/student_exam/student_result_screen.dart';
import 'package:olympic_it_project/service/profile_student_service.dart';

class ExamDetailsStudentScreen extends StatefulWidget {
  final int examId;
  const ExamDetailsStudentScreen({super.key, required this.examId});

  @override
  State<ExamDetailsStudentScreen> createState() =>
      _ExamDetailsStudentScreenState();
}

class _ExamDetailsStudentScreenState extends State<ExamDetailsStudentScreen> {
  final _service = ProfileStudentService();

  StudentExamDetailResponse? exam;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadExam();
  }

  Future<void> _joinRoom() async {
    try {
      final res = await _service.joinRoom(widget.examId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.message)));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentExamScreen(examId: widget.examId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _reconnect() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentExamScreen(examId: widget.examId),
      ),
    );
  }

  Future<void> _viewResult() async {
    try {
      final result = await _service.getExamResult(widget.examId);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamResultScreen(
            examId: widget.examId,
            initialResult: result,
            examName: exam?.name,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> loadExam() async {
    try {
      final res = await _service.getExamDetail(widget.examId);

      setState(() {
        exam = res;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });

      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (exam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Chi tiết đề thi")),
        body: const Center(child: Text("Không tải được thông tin đề thi")),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Chi tiết phòng thi",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1FF),
                          borderRadius: BorderRadius.circular(15),
                        ),

                        child: const Icon(
                          Icons.quiz,
                          color: Color(0xFF3B82F6),
                          size: 32,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Text(
                          exam!.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  _infoItem(
                    Icons.list_alt,
                    "Số câu hỏi",
                    "${exam!.totalQuestions} câu",
                  ),

                  const SizedBox(height: 15),

                  _infoItem(
                    Icons.info,
                    "Trạng thái",
                    _statusText(exam!.status),
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: _buildActionButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF3B82F6)),

        const SizedBox(width: 12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),

            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  String _statusText(String status) {
    switch (status) {
      case "WAITING":
        return "Chưa tạo phòng";

      case "ROOM_READY":
        return "Đang chờ bắt đầu";

      case "RUNNING":
        return "Đang thi";

      case "FINISHED":
        return "Đã kết thúc";

      default:
        return status;
    }
  }

  Widget _buildActionButton() {
    switch (exam!.status) {
      case "WAITING":
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: null,
          child: const Text(
            "Chưa mở phòng thi",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );

      case "ROOM_READY":
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),

          onPressed: _joinRoom,

          child: const Text(
            "Tham gia phòng",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );

      case "RUNNING":
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),

          onPressed: _reconnect,

          child: const Text(
            "Kết nối lại bài thi",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );

      case "FINISHED":
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),

          onPressed: _viewResult,

          child: const Text(
            "Xem kết quả",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );

      default:
        return const SizedBox();
    }
  }
}