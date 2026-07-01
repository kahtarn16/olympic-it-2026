import 'package:flutter/material.dart';

// Widget tag nhỏ hiển thị thông tin câu hỏi: chủ đề, độ khó, điểm, loại câu...
// Dùng chung cho tất cả loại câu hỏi — truyền màu khác nhau để phân biệt ý nghĩa
//
// Ví dụ dùng:
//   ExamTag(text: 'DỄ', backgroundColor: Color(0xFFFFE4E1), textColor: Color(0xFFFF4500))
//   ExamTag(text: 'TRẮC NGHIỆM', backgroundColor: Color(0xFFF3F4F6))
class ExamTag extends StatelessWidget {
  // Nội dung hiển thị trong tag
  final String text;

  // Icon emoji tuỳ chọn, hiển thị bên trái text (có thể bỏ qua)
  final String? icon;

  // Màu nền của tag
  final Color backgroundColor;

  // Màu chữ — mặc định đen nhạt nếu không truyền
  final Color textColor;

  const ExamTag({
    super.key,
    required this.text,
    this.icon,
    required this.backgroundColor,
    this.textColor = Colors.black87, // mặc định chữ đen nhạt
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        // Bo góc tròn kiểu pill
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        // Co lại vừa nội dung, không chiếm hết chiều ngang
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hiển thị icon nếu có truyền vào
          if (icon != null) ...[
            Text(icon!, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4), // khoảng cách giữa icon và text
          ],

          // Nội dung chữ của tag
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}