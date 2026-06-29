import 'package:flutter/material.dart';

class ExamStepHeader extends StatelessWidget {
  final int currentStep;

  const ExamStepHeader({super.key, required this.currentStep});

  bool isDone(int step) => step < currentStep;
  bool isActive(int step) => step == currentStep;

  Widget buildStep(int step, String label) {
    bool done = isDone(step);
    bool active = isActive(step);

    Color color;
    Widget child;

    if (done) {
      color = const Color(0xFF3B82F6);
      child = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (active) {
      color = const Color(0xFF3B82F6);
      child = Text(
        "$step",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    } else {
      color = Colors.grey.shade300;
      child = Text(
        "$step",
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 14, backgroundColor: color, child: child),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active || done ? FontWeight.bold : FontWeight.normal,
            color: active || done ? const Color(0xFF3B82F6) : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget buildLine(int step) {
    bool active = step < currentStep;

    return Expanded(
      child: Padding(
        // Đẩy đường gạch ngang xuống 14px để thẳng tâm với CircleAvatar (radius=14)
        padding: const EdgeInsets.only(bottom: 18.0), 
        child: Container(
          height: 2,
          color: active ? const Color(0xFF3B82F6) : Colors.grey.shade300,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- PHẦN THANH TIÊU ĐỀ TRÊN CÙNG MỚI THÊM ---
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                onPressed: () {
                  Navigator.maybePop(context); // Quay lại màn hình trước đó
                },
              ),
              const Text(
                "Tạo bài thi",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- PHẦN TIẾN TRÌNH CÁC BƯỚC (CŨ) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end, // Căn hàng dưới cùng để các line thẳng hàng
              children: [
                buildStep(1, "Thông tin"),
                buildLine(1),
                buildStep(2, "Câu hỏi"),
                buildLine(2),
                buildStep(3, "Cài đặt"),
                buildLine(3),
                buildStep(4, "Xem trước"),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)), // Đường kẻ mờ phân cách Header với Nội dung bài thi
        ],
      ),
    );
  }
}