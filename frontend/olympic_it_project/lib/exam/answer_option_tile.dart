import 'package:flutter/material.dart';

/// WIDGET CON: HIỂN THỊ Ô TÙY CHỌN ĐÁP ÁN (CHỈ ĐỔI MÀU KHI ĐƯỢC CHỌN, KHÔNG DÙNG ICON)
class AnswerOptionTile extends StatelessWidget {
  final String label;       // Chữ cái đại diện đầu câu (A, B, C, D)
  final String content;     // Nội dung chữ của câu trả lời
  final VoidCallback onTap; // Sự kiện xử lý khi người dùng ấn vào ô
  final String state;       // Trạng thái hiển thị nhận diện: 'normal', 'selected'

  const AnswerOptionTile({
    super.key,
    required this.label,
    required this.content,
    required this.onTap,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Khởi tạo màu sắc mặc định cho trạng thái thông thường (Chưa Chọn - normal)
    Color borderColor = Colors.grey.shade300; 
    Color backgroundColor = Colors.white;      
    Color textColor = Colors.black87;          
    Color circleColor = const Color(0xFFA3A3A3); // Màu gốc của vòng tròn chứa A, B, C, D

    // 2. Cấu hình màu sắc khi ô này ở trạng thái 'selected' (Đang Chọn)
    if (state == 'selected') {
      borderColor = const Color(0xFF3B82F6);     // Viền đổi sang Xanh Dương đậm
      backgroundColor = const Color(0xFFEFF6FF); // Nền đổi sang Xanh Dương siêu nhạt
      textColor = const Color(0xFF1D4ED8);       // Chữ câu trả lời đổi sang màu xanh tối
      circleColor = const Color(0xFF3B82F6);     // Vòng tròn chữ cái cũng chuyển sang màu xanh dương
    }

    return Padding(
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
              width: state == 'selected' ? 2.0 : 1.0, // Tăng độ dày viền khi được chọn để tạo điểm nhấn
            ), 
          ),
          child: Row(
            children: [
              // Thành phần 1: Vòng tròn chứa ký tự chữ cái đầu dòng (A, B, C, D)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 16), 
              
              // Thành phần 2: Khối Text chứa nội dung câu trả lời
              Expanded(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor, 
                    fontWeight: state == 'selected' ? FontWeight.w700 : FontWeight.w500, // Chữ in đậm hơn khi được chọn
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