import 'package:flutter/material.dart';

class EssayInputField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const EssayInputField({
    super.key,
    required this.controller,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<EssayInputField> createState() => _EssayInputFieldState();
}

class _EssayInputFieldState extends State<EssayInputField> {
  int _charCount = 0;
  static const int _maxLength = 50;

  @override
  void initState() {
    super.initState();
    _charCount = widget.controller.text.length;
    widget.controller.addListener(_updateCharCount);
  }

  void _updateCharCount() {
    setState(() {
      _charCount = widget.controller.text.length;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCharCount);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tự động tính toán màu dựa trên trạng thái enabled
    final backgroundColor = widget.enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6);
    final borderColor = widget.enabled ? const Color(0xFFE5E7EB) : const Color(0xFFD1D5DB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 180, // Chiều cao cố định phù hợp để nhập tự luận
          decoration: BoxDecoration(
            color: backgroundColor, // Đã sửa: Sử dụng biến động thay vì gán cứng
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor, // Đã sửa: Sử dụng biến động thay vì gán cứng
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Ô nhập văn bản chính
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  maxLength: _maxLength,
                  maxLines: null, // Cho phép xuống dòng tự động
                  keyboardType: TextInputType.multiline,
                  onChanged: widget.onChanged,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    // Nếu hết giờ (disabled) thì làm mờ chữ đi
                    color: widget.enabled ? Colors.black87 : Colors.black38,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.enabled 
                        ? 'Nhập câu trả lời của bạn tại đây...' 
                        : 'Đã hết thời gian làm bài!',
                    hintStyle: TextStyle(
                      color: widget.enabled ? const Color(0xFF9CA3AF) : Colors.red.withOpacity(0.5),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    counterText: '', // Ẩn counter mặc định
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              // Bộ đếm kí tự nằm góc dưới bên phải
              if (widget.enabled)
                Positioned(
                  bottom: 12,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFF3F4F6),
                      ),
                    ),
                    child: Text(
                      '$_charCount/$_maxLength',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _charCount >= _maxLength 
                            ? Colors.red 
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}