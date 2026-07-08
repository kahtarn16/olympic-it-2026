import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:olympic_it_project/dto/profile/student_me_response.dart';
import 'package:olympic_it_project/screen/auth/login_screen.dart';
import 'package:olympic_it_project/screen/student_exam/change_password_screen.dart';
import 'package:olympic_it_project/service/auth_service.dart';
import 'package:olympic_it_project/service/profile_student_service.dart';

// Đảm bảo thay đổi các đường dẫn import này cho đúng với cấu trúc thư mục của bạn
// import 'package:olympic_it_project/dto/profile/student_me_response.dart';

class ProfileStudentScreen extends StatefulWidget {
  const ProfileStudentScreen({super.key});

  @override
  State<ProfileStudentScreen> createState() => _ProfileStudentScreenState();
}

class _ProfileStudentScreenState extends State<ProfileStudentScreen> {
  final ProfileStudentService _studentService = ProfileStudentService();
  late Future<StudentMeResponse> _profileFuture;

  // Cấu hình mã màu Modern cao cấp trực tiếp trong Code để không bị lệch màu Theme gốc
  static const Color kPrimaryColor = Color.fromARGB(255, 145, 171, 216); // Deep Navy (Xanh biển sâu lịch lãm)
  static const Color kAccentColor = Color(0xFF3B82F6);  // Electric Blue (Xanh công nghệ làm điểm nhấn)
  static const Color kBackgroundColor = Color(0xFFF8FAFC); // Slate Light (Nền xám trắng siêu dịu mắt)
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF0F172A); // Charcoal (Chữ đen than, không bị gắt như thuần đen)
  static const Color kSubtextColor = Color(0xFF64748B); // Slate Gray (Chữ phụ xám tinh tế)

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _profileFuture = _studentService.getMe().then(
            (jsonMap) => StudentMeResponse.fromJson(jsonMap),
          );
    });
  }

  void _handleLogout() {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text("Đăng xuất"),
          content: const Text("Bạn có chắc chắn muốn rời khỏi hệ thống không?"),
          actions: [
            CupertinoDialogAction(
              child: const Text("Hủy", style: TextStyle(color: kSubtextColor)),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text("Đăng xuất"),
              onPressed: () {
                Navigator.pop(context);
                logout();
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: kCardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Đăng xuất", style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold)),
          content: const Text("Bạn có chắc chắn muốn rời khỏi hệ thống không?", style: TextStyle(color: kSubtextColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy", style: TextStyle(color: kSubtextColor)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                logout();
              },
              child: const Text("Đăng xuất", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToChangePassword(String studentEmail) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ChangePasswordScreen(email: studentEmail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Hồ sơ sinh viên", 
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: kTextColor, letterSpacing: -0.3)
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent, // Làm trong suốt AppBar để hòa vào nền tinh tế
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<StudentMeResponse>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation<Color>(kAccentColor)));
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.blur_on_rounded, color: kSubtextColor, size: 40),
                    const SizedBox(height: 12),
                    Text("Không thể tải thông tin", style: TextStyle(color: kSubtextColor.withOpacity(0.8))),
                    TextButton(onPressed: _loadProfile, child: const Text("Tải lại", style: TextStyle(color: kAccentColor)))
                  ],
                ),
              );
            }

            if (!snapshot.hasData) return const Center(child: Text("Không có dữ liệu"));

            final student = snapshot.data!;

            return RefreshIndicator(
              color: kAccentColor,
              onRefresh: () async => _loadProfile(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- KHỐI PROFILE HEADER (AVATAR MỚI) ---
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: kPrimaryColor, // Nền Navy đậm quyền lực
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimaryColor.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : "S",
                              style: const TextStyle(fontSize: 34, color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            student.fullName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextColor, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 6),
                          if (student.academicYear != null && student.academicYear!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: kAccentColor.withOpacity(0.08), // Màu pastel nhẹ nhàng
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                "Khóa ${student.academicYear}",
                                style: const TextStyle(fontSize: 12, color: kAccentColor, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // --- NHÓM THÔNG TIN ---
                    _buildSectionTitle("THÔNG TIN HỌC TẬP"),
                    Container(
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color.fromARGB(255, 120, 124, 129)), // Viền cực mảnh xám slate nhạt
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.person_outline_rounded, "Tài khoản", student.username),
                          _buildInnerDivider(),
                          _buildInfoRow(Icons.mail_outline_rounded, "Email", student.email),
                          _buildInnerDivider(),
                          _buildInfoRow(Icons.widgets_outlined, "Lớp", student.className ?? "Chưa xếp lớp"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // --- NHÓM HỆ THỐNG & BẢO MẬT ---
                    _buildSectionTitle("TÀI KHOẢN & BẢO MẬT"),
                    Container(
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color.fromARGB(255, 120, 124, 129)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // Hàng đổi mật khẩu tinh tế
                          InkWell(
                            onTap: () => _navigateToChangePassword(student.email),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.key_rounded, color: kSubtextColor, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  const Text("Đổi mật khẩu", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: kTextColor)),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 14),
                                ],
                              ),
                            ),
                          ),
                          _buildInnerDivider(),
                          // Hàng đăng xuất mềm mại phá cách
                          InkWell(
                            onTap: _handleLogout,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)), // Nền đỏ hồng pastel cực nhạt
                                    child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20), // Icon đỏ Modern
                                  ),
                                  const SizedBox(width: 14),
                                  const Text("Đăng xuất", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFFEF4444))),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFCA5A5), size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kSubtextColor, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: kSubtextColor, size: 20),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontSize: 14, color: kSubtextColor, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextColor, letterSpacing: -0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildInnerDivider() {
    return const Divider(height: 1, indent: 54, endIndent: 0, color: Color(0xFFF1F5F9));
  }
  Future<void> logout() async {
    await AuthService().logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}