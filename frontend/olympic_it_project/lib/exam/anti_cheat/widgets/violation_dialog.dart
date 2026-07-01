import 'package:flutter/material.dart';
import '../cubit/anti_cheat_cubit.dart';

// Dialog cảnh báo vi phạm — hiện khi AntiCheatCubit emit ViolationDetected
// Thiết kế theo ảnh mẫu:
//   - Icon cảnh báo
//   - Tiêu đề "CẢNH BÁO CUỐI CÙNG!" (khi lần 2) hoặc "CẢNH BÁO!" (lần 1)
//   - Loại vi phạm + thời gian
//   - Lần vi phạm X/3 + còn lại N cơ hội
//   - Quy định bài thi
//   - Nút "Tiếp tục thi" / "Kết thúc"
//
// Cách dùng:
//   ViolationDialog.show(context, log: log, totalViolations: 2,
//     onContinue: () {}, onEnd: () {});
class ViolationDialog extends StatelessWidget {
  // Thông tin log vi phạm vừa xảy ra
  final ViolationLog log;

  // Tổng số vi phạm tính đến lần này
  final int totalViolations;

  // Callback khi nhấn "Tiếp tục thi"
  final VoidCallback onContinue;

  // Callback khi nhấn "Kết thúc" — nộp bài + cấm thi
  final VoidCallback onEnd;

  const ViolationDialog({
    super.key,
    required this.log,
    required this.totalViolations,
    required this.onContinue,
    required this.onEnd,
  });

  // Số cơ hội còn lại
  int get _remainingChances => 3 - totalViolations;

  // Tiêu đề thay đổi theo mức độ vi phạm
  String get _title {
    if (totalViolations >= 2) return '⚠️ CẢNH BÁO CUỐI CÙNG!';
    return '⚠️ CẢNH BÁO!';
  }

  // Màu badge vi phạm — đỏ khi gần hết cơ hội
  Color get _badgeColor {
    if (totalViolations >= 2) return const Color(0xFFFFE4E1);
    return const Color(0xFFFFF3CD);
  }

  Color get _badgeTextColor {
    if (totalViolations >= 2) return const Color(0xFFDC2626);
    return const Color(0xFF92400E);
  }

  // Static method để show dialog dễ dàng từ bất kỳ đâu
  static Future<void> show(
    BuildContext context, {
    required ViolationLog log,
    required int totalViolations,
    required VoidCallback onContinue,
    required VoidCallback onEnd,
  }) {
    return showDialog(
      context: context,
      // Không cho đóng dialog bằng cách nhấn ra ngoài
      barrierDismissible: false,
      builder: (_) => ViolationDialog(
        log: log,
        totalViolations: totalViolations,
        onContinue: onContinue,
        onEnd: onEnd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // Bo góc dialog
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      // Padding ngoài dialog — responsive theo màn hình
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min, // dialog cao vừa đủ nội dung
          children: [
            // ── ICON CẢNH BÁO ────────────────────────────────────────────
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE4E1), // nền đỏ nhạt
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626), // đỏ đậm
                size: 36,
              ),
            ),

            const SizedBox(height: 16),

            // ── TIÊU ĐỀ ──────────────────────────────────────────────────
            Text(
              _title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // ── LOẠI VI PHẠM ─────────────────────────────────────────────
            Text(
              log.type.label, // ví dụ: "Cửa sổ đã mất focus"
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF374151),
              ),
            ),

            const SizedBox(height: 4),

            // ── THỜI GIAN VI PHẠM ─────────────────────────────────────────
            Text(
              // Format: HH:MM:SS
              'Thời gian: ${_formatTime(log.time)}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280), // xám nhạt
              ),
            ),

            const SizedBox(height: 16),

            // ── BADGE: LẦN VI PHẠM X/3 ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _badgeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Lần vi phạm: $totalViolations/3',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _badgeTextColor,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── SỐ CƠ HỘI CÒN LẠI ───────────────────────────────────────
            Text(
              'Còn lại $_remainingChances cơ hội',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),

            const SizedBox(height: 20),

            // ── QUY ĐỊNH BÀI THI ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB), // nền xám rất nhạt
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề quy định
                  const Text(
                    '📋 Quy định bài thi:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Danh sách quy định
                  ..._rules.map(
                    (rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $rule',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 2 NÚT HÀNH ĐỘNG ──────────────────────────────────────────
            Row(
              children: [
                // Nút "Tiếp tục thi" — xanh dương
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // đóng dialog
                      onContinue(); // tiếp tục thi
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Tiếp tục thi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Nút "Kết thúc" — xám
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // đóng dialog
                      onEnd(); // nộp bài + cấm thi
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B7280),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Kết thúc',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Format DateTime thành HH:MM:SS
  String _formatTime(DateTime time) {
    final String h = time.hour.toString().padLeft(2, '0');
    final String m = time.minute.toString().padLeft(2, '0');
    final String s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // Danh sách quy định hiển thị trong dialog
  // TODO: REPLACE WITH API — lấy từ server nếu quy định có thể thay đổi
  static const List<String> _rules = [
    'Không được chuyển tab hoặc minimize cửa sổ',
    'Không được thoát khỏi chế độ toàn màn hình',
    'Không được sao chép/dán nội dung',
    'Không được chia đôi màn hình',
    'Vi phạm 3 lần sẽ bị tự động nộp bài',
  ];
}