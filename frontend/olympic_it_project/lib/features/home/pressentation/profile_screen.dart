import 'package:flutter/material.dart';
import 'package:olympic_it_project/features/home/pressentation/profile_screen.dart';
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFDCEEFF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildAvatar(),
              const SizedBox(height: 20),
              _buildInfoCard(),
              const Spacer(),

              _buildButton(
                text: "Thông tin trận đấu",
                onPressed: () {
                  // TODO
                },
              ),

              const SizedBox(height: 15),

              _buildButton(
                text: "Đổi mật khẩu",
                onPressed: () {
                  // TODO
                },
              ),

              const SizedBox(height: 15),

              _buildButton(
                text: "Đăng xuất",
                icon: Icons.logout,
                iconColor: Colors.red,
                onPressed: () {
                  // TODO
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
            ),
            child: const Icon(Icons.arrow_back_ios_new),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          "Thông tin cá nhân",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return const CircleAvatar(
      radius: 45,
      backgroundColor: Colors.orange,
      child: Icon(
        Icons.person,
        size: 55,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Thông tin thí sinh",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          _buildRow("Họ tên", "Lâm Quốc Phong"),
          _buildRow("Lớp", "CDTH22 DD"),
          _buildRow("Email", "0306231234@caothang.edu.vn"),
          _buildRow("MSSV", "0306221234"),
        ],
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              "$title:",
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    IconData? icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.black,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF39B4F3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 10),
              Icon(
                icon,
                color: iconColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}