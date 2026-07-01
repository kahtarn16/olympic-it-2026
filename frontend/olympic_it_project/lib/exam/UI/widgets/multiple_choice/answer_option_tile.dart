import 'package:flutter/material.dart';

// Widget hiển thị một ô đáp án trắc nghiệm (A, B, C, D)
// Chỉ dùng cho loại câu hỏi TRẮC NGHIỆM — không dùng cho tự luận
//
// Trạng thái hiển thị được truyền qua [state]:
//   'normal'   — chưa chọn, màu mặc định trắng/xám
//   'selected' — đang chọn, màu xanh dương nổi bật
class AnswerOptionTile extends StatelessWidget {
  // Chữ cái đại diện đầu câu: 'A', 'B', 'C', 'D'
  final String label;

  // Nội dung câu trả lời
  final String content;

  // Sự kiện khi người dùng nhấn vào ô
  // Được xử lý từ screen — screen quyết định có cho chọn không (dựa vào remainingSeconds)
  final VoidCallback onTap;

  // Trạng thái hiển thị: 'normal' hoặc 'selected'
  // TODO: REPLACE WITH API — sau này có thể thêm 'correct' / 'wrong'
  //       khi server trả về kết quả sau khi nộp bài
  final String state;

  const AnswerOptionTile({
    super.key,
    required this.label,
    required this.content,
    required this.onTap,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // ── MÀU SẮC THEO TRẠNG THÁI ─────────────────────────────────────────────

    // Màu viền mặc định khi chưa chọn
    Color borderColor = Colors.grey.shade300;

    // Màu nền mặc định khi chưa chọn
    Color backgroundColor = Colors.white;

    // Màu chữ nội dung mặc định
    Color textColor = Colors.black87;

    // Màu vòng tròn chứa chữ cái A/B/C/D mặc định
    Color circleColor = const Color(0xFFA3A3A3);

    // Cập nhật màu sắc khi ô đang ở trạng thái 'selected'
    if (state == 'selected') {
      borderColor = const Color(0xFF3B82F6);      // viền xanh dương đậm
      backgroundColor = const Color(0xFFEFF6FF);  // nền xanh dương siêu nhạt
      textColor = const Color(0xFF1D4ED8);        // chữ xanh tối
      circleColor = const Color(0xFF3B82F6);      // vòng tròn xanh dương
    }

    return Padding(
      // Khoảng cách giữa các ô đáp án
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              // Viền dày hơn khi được chọn để tạo điểm nhấn
              width: state == 'selected' ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // ── VÒNG TRÒN CHỮ CÁI ─────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  label, // 'A', 'B', 'C', 'D'
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // ── NỘI DUNG ĐÁP ÁN ───────────────────────────────────────
              Expanded(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    // Chữ đậm hơn khi được chọn
                    fontWeight: state == 'selected'
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}