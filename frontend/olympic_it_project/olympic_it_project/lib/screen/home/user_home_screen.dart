import 'package:flutter/material.dart';
import 'package:olympic_it_project/screen/student_exam/exam_details_student_screen.dart';
import 'package:olympic_it_project/screen/auth/login_screen.dart';
import 'package:olympic_it_project/screen/student_exam/profile_student_screen.dart';
import 'package:olympic_it_project/service/auth_service.dart';
import 'package:olympic_it_project/service/profile_student_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final _profileService = ProfileStudentService();

  Map<String, dynamic>? user;
  List<dynamic> exams = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  String getStatusText(String status) {
    switch (status) {
      case "RUNNING":
        return "Đang thi";
      case "ROOM_READY":
        return "Phòng thi đã sẵn sàng";
      case "WAITING":
        return "Đang chờ";
      case "FINISHED":
        return "Đã xong";
      default:
        return "Không xác định";
    }
  }

  Future<void> loadData() async {
    try {
      final me = await _profileService.getMe();
      final myExams = await _profileService.getMyExams();

      setState(() {
        user = me;
        exams = myExams;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Color getColor(String status) {
    switch (status) {
      case "RUNNING":
        return Colors.green;
      case "WAITING":
        return Colors.orange;
      case "FINISHED":
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void openExam(int examId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamDetailsStudentScreen(examId: examId),
      ),
    );
  }

  Future<void> refreshData() async {
    await loadData();
  }

  Future<void> logout() async {
    await AuthService().logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B82F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Olympic IT",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 15),

                    // ===== LOGO =====
                    Image.asset(
                      "assets/images/logo_caothang.webp",
                      width: 110,
                      height: 110,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "Olympic IT 2026",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      "Hệ thống thi trực tuyến",
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),

                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () {
                        // Chuyển sang trang Profile. Nhớ thay 'ProfilePage()' bằng class trang của bạn nhé.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileStudentScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.1),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: Color(0xFFE8F1FF),
                              child: Icon(
                                Icons.person,
                                color: Color(0xFF3B82F6),
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Xin chào 👋",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?['fullName'] ?? "Sinh viên",
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?['email'] ?? "",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Danh sách phòng thi",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 21,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ===== EXAM LIST =====
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.1),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: exams.map((e) {
                          return Card(
                            elevation: 1,
                            child: ListTile(
                              leading: const Icon(
                                Icons.description,
                                color: Color(0xFF3B82F6),
                              ),
                              title: Text(e['examName'] ?? ''),
                              subtitle: Text("Mã phòng thi: ${e['examId']}"),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: getColor(
                                    e['status'],
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  getStatusText(e['status']),
                                  style: TextStyle(
                                    color: getColor(e['status']),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () => openExam(e['examId']),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
    );
  }
}
