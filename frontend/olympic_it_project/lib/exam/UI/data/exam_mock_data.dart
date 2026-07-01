class ExamMockData {
  // ── THÔNG TIN CHUNG CÂU HỎI ──────────────────────────────────────────────

  // TODO: Lấy từ API — tổng số câu hỏi trong phòng thi
  static const int totalQuestions = 12;

  // TODO: Lấy từ API — số thứ tự câu hỏi hiện tại (1-based)
  static const int currentQuestion = 2;

  // TODO: Lấy từ API — thời gian làm bài của câu này (giây, tối đa 75)
  static const int remainingSeconds = 15;

  // TODO: Lấy từ API — loại câu hỏi: 'TRẮC NGHIỆM' hoặc 'TỰ LUẬN'
  static const String questionStyle = 'TỰ LUẬN';

  // TODO: Lấy từ API — độ khó: 'DỄ' | 'TRUNG BÌNH' | 'KHÓ'
  static const String difficulty = 'DỄ';

  // TODO: Lấy từ API — chủ đề câu hỏi
  static const String topic = 'Tin học ứng dụng';

  // TODO: Lấy từ API — điểm thưởng nếu trả lời đúng
  static const int point = 30;

  // ── NỘI DUNG CÂU HỎI ─────────────────────────────────────────────────────

  // TODO: Lấy từ API — nội dung đề bài
  static const String questionText =
      'Bạn cần bấm tổ hợp phím tắt nào để bôi đen đoạn văn này?';

  // TODO: Lấy từ API — đường dẫn ảnh minh hoạ (null nếu không có)
  // Khi có server: đây sẽ là URL ảnh, không phải asset path
  static const String? imageAssetPath = null;

  // TODO: Lấy từ API — URL video từ server (null nếu không có)
  static const String? videoUrl = 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';

  // ── ĐÁP ÁN TRẮC NGHIỆM ───────────────────────────────────────────────────

  // TODO: Lấy từ API — danh sách đáp án A/B/C/D
  static const List<Map<String, String>> options = [
    {'label': 'A', 'content': '2'},
    {'label': 'B', 'content': '"11"'},
    {'label': 'C', 'content': 'Lỗi biên dịch'},
    {'label': 'D', 'content': 'Tất cả đều sai'},
  ];

  static const int loadingDurationSeconds = 5;
}