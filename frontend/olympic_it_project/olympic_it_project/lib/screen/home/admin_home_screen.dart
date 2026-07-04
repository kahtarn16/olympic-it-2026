import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:olympic_it_project/screen/admin_manager/academic_year_screen.dart';
import 'package:olympic_it_project/screen/admin_manager/category_screen.dart';
import 'package:olympic_it_project/screen/admin_manager/classes_screen.dart';
import 'package:olympic_it_project/screen/admin_manager/exam_screen.dart';
import 'package:olympic_it_project/screen/admin_manager/question_screen.dart';
import 'package:olympic_it_project/screen/admin_manager/student_screen.dart';
import 'package:olympic_it_project/screen/auth/login_screen.dart';
import 'package:olympic_it_project/service/auth_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Future<void> _showLogoutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.only(top: 24),
          title: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.red.shade50,
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Đăng xuất",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Hủy"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Đăng xuất",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (result == true) {
      await AuthService().logout();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
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
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 15),

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
              "Hệ thống quản trị",
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),

            const SizedBox(height: 25),

            Container(
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
                      Icons.admin_panel_settings,
                      color: Color(0xFF3B82F6),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Xin chào 👋",
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Admin",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Quản trị viên",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Quản lý hệ thống",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                ),
              ),
            ),

            const SizedBox(height: 15),

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
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: .95,
                children: [
                  _menuCard(Icons.school, "Khóa học", Colors.blue, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AcademicYearScreen(),
                      ),
                    );
                  }),
                  _menuCard(Icons.class_, "Lớp học", Colors.orange, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ClassesScreen()),
                    );
                  }),
                  _menuCard(Icons.people, "Sinh viên", Colors.green, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentScreen()),
                    );
                  }),
                  _menuCard(
                    Icons.description,
                    "Đề thi",
                    Colors.deepPurple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExamScreen()),
                      );
                    },
                  ),
                  _menuCard(Icons.quiz, "Câu hỏi", Colors.red, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QuestionScreen()),
                    );
                  }),
                  _menuCard(Icons.category, "Loại câu hỏi", Colors.indigo, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CategoryScreen()),
                    );
                  }),
                  _menuCard(Icons.bar_chart, "Kết quả", Colors.teal, () {}),
                ],
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(.12),
              child: Icon(icon, size: 34, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
