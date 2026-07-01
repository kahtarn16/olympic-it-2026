import 'package:flutter/material.dart';
import 'responsive_layout.dart';

// Widget header dùng chung cho tất cả loại câu hỏi
// Responsive: tự scale font, padding, kích thước đồng hồ theo màn hình
class ExamHeader extends StatelessWidget {
  // Số thứ tự câu hỏi hiện tại
  final int currentQuestion;

  // Tổng số câu hỏi trong bài thi
  final int totalQuestions;

  // Số giây còn lại — truyền từ CountdownCubit
  final int remainingSeconds;

  const ExamHeader({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.remainingSeconds,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình để tính toán responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < AppBreakpoint.phone;

    // Font size tự động theo màn hình
    final double questionFontSize = isPhone ? 18 : 22;
    final double timerFontSize = isPhone ? 20 : 24;

    // Kích thước đồng hồ tự động theo màn hình
    final double timerSize = isPhone ? 50 : 60;

    // Padding header tự động theo màn hình
    final double headerPadding = isPhone ? 12 : 16;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(headerPadding),
      decoration: const BoxDecoration(
        color: Color(0xFF3B82F6),
        borderRadius: BorderRadius.all(Radius.circular(25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── PHẦN TRÁI: số câu hiện tại / tổng câu ──────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              isPhone ? 8 : 10,
              16,
              isPhone ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Icon câu hỏi — size tự động
                Text(
                  '❓ ',
                  style: TextStyle(fontSize: isPhone ? 16 : 20),
                ),

                // Số câu "01/12" — màu cam / màu đen
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: questionFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        // Thêm số 0 phía trước nếu < 10
                        text: currentQuestion.toString().padLeft(2, '0'),
                        style: const TextStyle(color: Colors.orange),
                      ),
                      TextSpan(
                        text: '/$totalQuestions',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── PHẦN PHẢI: đồng hồ đếm ngược ───────────────────────────────
          // Đổi màu sang đỏ khi còn ít hơn 10 giây — cảnh báo thí sinh
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: timerSize,
            height: timerSize,
            decoration: BoxDecoration(
              // Đỏ khi < 10 giây, tím khi còn nhiều giờ
              color: remainingSeconds <= 10
                  ? Colors.red.withOpacity(0.8)
                  : const Color.fromARGB(255, 36, 4, 88).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$remainingSeconds',
              style: TextStyle(
                color: Colors.white,
                fontSize: timerFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}