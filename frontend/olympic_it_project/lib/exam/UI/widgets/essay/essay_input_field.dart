import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final backgroundColor = widget.enabled
        ? const Color(0xFFF9FAFB)
        : const Color(0xFFF3F4F6);
    final borderColor = widget.enabled
        ? const Color(0xFFE5E7EB)
        : const Color(0xFFD1D5DB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 180, // Chiều cao cố định phù hợp để nhập tự luận
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
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

                  // ── CHẶN PASTE TỪ BÀN PHÍM (Ctrl+V / Cmd+V) ──────────────
                  // _NoPasteFormatter kiểm tra từng ký tự được nhập vào
                  // Nếu phát hiện nội dung được paste (dài hơn 1 ký tự cùng lúc)
                  // thì từ chối — thí sinh chỉ được gõ từng ký tự một
                  inputFormatters: [
                    _NoPasteFormatter(),
                  ],

                  // ── CHẶN MENU COPY/PASTE KHI LONG PRESS / CHUỘT PHẢI ─────
                  // Trả về widget rỗng thay vì menu mặc định
                  // → thí sinh không thấy tùy chọn Paste, Copy, Cut, Select All
                  contextMenuBuilder: (context, editableTextState) {
                    return const SizedBox.shrink();
                  },

                  decoration: InputDecoration(
                    hintText: widget.enabled
                        ? 'Nhập câu trả lời của bạn tại đây...'
                        : 'Đã hết thời gian làm bài!',
                    hintStyle: TextStyle(
                      color: widget.enabled
                          ? const Color(0xFF9CA3AF)
                          : Colors.red.withOpacity(0.5),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                        // Đỏ khi đạt giới hạn, xám khi còn chỗ
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

// ════════════════════════════════════════════════════════════════════════════
// FORMATTER CHẶN PASTE
// Kế thừa TextInputFormatter — được Flutter gọi mỗi khi có nội dung mới
// được nhập vào TextField
// ════════════════════════════════════════════════════════════════════════════

class _NoPasteFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // giá trị trước khi nhập
    TextEditingValue newValue, // giá trị sau khi nhập
  ) {
    // Tính số ký tự thay đổi giữa lần nhập cũ và mới
    final int oldLength = oldValue.text.length;
    final int newLength = newValue.text.length;
    final int diff = newLength - oldLength;

    // Nếu số ký tự tăng hơn 1 cùng lúc → là paste
    // Gõ bàn phím bình thường chỉ tăng 1 ký tự mỗi lần
    if (diff > 1) {
      // Từ chối thay đổi — giữ nguyên giá trị cũ
      return oldValue;
    }

    // Cho phép — là gõ bình thường hoặc xoá
    return newValue;
  }
}