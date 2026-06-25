import 'package:flutter/material.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const PersonalInfoHeader(),

              const SizedBox(height: 12),

              const CandidateInfoCard(),

              const Spacer(),

              ActionButton(
                text: "Quên mật khẩu",
                onPressed: () {},
              ),

              const SizedBox(height: 12),

              ActionButton(
                text: "Đăng xuất",
                onPressed: () {},
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class PersonalInfoHeader extends StatelessWidget {
  const PersonalInfoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        "Thông tin cá nhân",
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class CandidateInfoCard extends StatelessWidget {
  const CandidateInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: const [
          Text(
            "Thông tin thí sinh",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 20),

          InfoRow(
            title: "Họ tên:",
            value: "Nguyễn Văn A",
          ),

          SizedBox(height: 16),

          InfoRow(
            title: "Lớp:",
            value: "CDTH23DDD",
          ),

          SizedBox(height: 16),

          InfoRow(
            title: "Email:",
            value: "0306231234@caothang.edu.vn",
          ),

          SizedBox(height: 16),

          InfoRow(
            title: "MSSV:",
            value: "0306231234",
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const InfoRow({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 16,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF3B82F6),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF3B82F6),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}