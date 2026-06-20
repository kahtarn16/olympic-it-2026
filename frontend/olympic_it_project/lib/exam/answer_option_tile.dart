import 'package:flutter/material.dart';

/// WIDGET CON: HIỂN THỊ Ô TÙY CHỌN ĐÁP ÁN (ĐÚNG TÔ XANH + v / SAI TÔ ĐỎ + x)
class AnswerOptionTile extends StatelessWidget {
  final String label;       // Chữ cái đại diện đầu câu (A, B, C, D)
  final String content;     // Nội dung chữ của câu trả lời
  final VoidCallback onTap; // Sự kiện xử lý khi người dùng ấn vào ô
  final String state;       // Trạng thái hiển thị nhận diện: 'normal', 'correct', 'wrong'

  const AnswerOptionTile({
    super.key,
    required this.label,
    required this.content,
    required this.onTap,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // Khởi tạo các giá trị màu sắc mặc định cho trạng thái thông thường (Chưa Chọn)
    Color borderColor = Colors.black87;       
    Color backgroundColor = Colors.white;      
    Color textColor = Colors.black87;          
    IconData? suffixIcon;                      
    Color? iconColor;                          

    // Cấu hình lại màu sắc dựa trên biến trạng thái hệ thống trả về
    if (state == 'correct') {
      borderColor = const Color(0xFF10B981);     // Viền màu Xanh lá đậm
      backgroundColor = const Color(0xFFECFDF5); // Nền màu Xanh lá siêu nhạt
      textColor = const Color(0xFF047857);       // Chữ màu Xanh đậm
      suffixIcon = Icons.check_circle;           // Icon dấu tích "v" tròn ở cuối hàng
      iconColor = const Color(0xFF10B981);       
    } else if (state == 'wrong') {
      borderColor = const Color(0xFFEF4444);     // Viền màu Đỏ đậm
      backgroundColor = const Color(0xFFFEF2F2); // Nền màu Đỏ siêu nhạt
      textColor = const Color(0xFFB91C1C);       // Chữ màu Đỏ đậm
      suffixIcon = Icons.cancel;                 // Icon dấu chéo "x" tròn ở cuối hàng
      iconColor = const Color(0xFFEF4444);       
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
            border: Border.all(color: borderColor, width: 1.5), 
          ),
          child: Row(
            children: [
              // Vòng tròn chứa ký tự chữ cái đầu dòng (A, B, C, D)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: state == 'normal' ? const Color(0xFFA3A3A3) : borderColor,
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
              
              // Khối Text chứa nội dung câu trả lời
              Expanded(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Nếu có Icon dấu 'v' hoặc 'x' thì tiến hành vẽ nó ở CUỐI HÀNG
              if (suffixIcon != null) ...[
                const SizedBox(width: 8), 
                Icon(suffixIcon, color: iconColor, size: 24), 
              ]
            ],
          ),
        ),
      ),
    );
  }
}