import 'dart:async';
import 'package:flutter/material.dart';
import 'package:olympic_it_project/exam/UI/data/exam_mock_data.dart';
import 'package:olympic_it_project/exam/UI/widgets/essay/essay_input_field.dart';
import '../widgets/shared/exam_header.dart';
import '../widgets/shared/exam_tag.dart';
import '../widgets/shared/question_card.dart';
import '../widgets/shared/responsive_layout.dart';
import '../widgets/multiple_choice/answer_option_tile.dart';

// Màn hình thi TRẮC NGHIỆM
// SafeArea đầy đủ 4 cạnh — tránh notch, Dynamic Island, camera, home indicator
// Header cố định trên cùng — không cuộn theo nội dung
// Responsive: phone toàn màn hình, tablet/desktop giới hạn 700px căn giữa
//
// TODO: REPLACE WITH API — toàn bộ data lấy từ ExamMockData
class EssayExamScreen extends StatefulWidget {
  const EssayExamScreen({super.key});

  @override
  State<EssayExamScreen> createState() => _EssayExamScreenState();
}

class _EssayExamScreenState extends State<EssayExamScreen> {
  // TODO: REPLACE WITH API — lấy từ ExamCubit state
  int totalQuestions = ExamMockData.totalQuestions;
  int numberQuestion = ExamMockData.currentQuestion;
  String? questionStyle = ExamMockData.questionStyle;
  String? difficulty = ExamMockData.difficulty;
  String? topic = ExamMockData.topic;
  int point = ExamMockData.point;
  final TextEditingController _essayController = TextEditingController();
  bool _isConfirming = false; // Mặc định chưa bấm trả lời
  bool _isSubmitted = false;

  // TODO: REPLACE WITH API — lấy từ CountdownCubit
  int remainingSeconds = ExamMockData.remainingSeconds;

  // TODO: REPLACE WITH API — xoá Timer khi tích hợp CountdownCubit
  Timer? _timer;

  // Đáp án thí sinh đang chọn
  String? selectedAnswer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  // TODO: REPLACE WITH API — xoá hàm này khi có CountdownCubit
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        _timer?.cancel();
        _handleTimeout();
      }
    });
  }

  // TODO: REPLACE WITH API — gọi ExamCubit.submitAnswer(isTimeout: true)
  void _handleTimeout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hết giờ làm bài! Hệ thống tự động ghi nhận đáp án'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Padding tự động theo kích thước màn hình
    final EdgeInsets padding = responsivePadding(context);
    final bool isInteractable = remainingSeconds > 0 && !_isSubmitted;

    return Scaffold(
      backgroundColor: Colors.white,
      // SafeArea bảo vệ đủ 4 cạnh:
      // top    — notch, Dynamic Island, punch-hole camera
      // bottom — home indicator (iPhone), gesture navigation bar (Android)
      // left   — camera cạnh trên một số Android
      // right  — camera cạnh trên một số Android
      body: SafeArea(
        // Tất cả 4 cạnh mặc định true — ghi rõ để dễ đọc
        top: true,
        bottom: true,
        left: true,
        right: true,
        child: ResponsiveExamLayout(
          child: Column(
            children: [
              // ── 1. HEADER CỐ ĐỊNH ────────────────────────────────────────
              // Nằm ngoài SingleChildScrollView — không cuộn theo nội dung
              Padding(
                padding: EdgeInsets.fromLTRB(
                  padding.left,
                  padding.top,
                  padding.right,
                  0,
                ),
                child: ExamHeader(
                  currentQuestion: numberQuestion,
                  totalQuestions: totalQuestions,
                  remainingSeconds: remainingSeconds,
                ),
              ),

              // ── 2. NỘI DUNG CUỘN ĐƯỢC ────────────────────────────────────
              // Expanded giúp phần scroll chiếm hết không gian còn lại
              Expanded(
                child: SingleChildScrollView(
                  //physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── TAG THÔNG TIN ─────────────────────────────────
                        Wrap(
                          spacing: 5,
                          runSpacing: 8,
                          children: [
                            ExamTag(
                              text: 'CÂU $numberQuestion',
                              icon: '❓',
                              backgroundColor: const Color(0xFFF3F4F6),
                            ),
                            if (questionStyle != null)
                              ExamTag(
                                text: questionStyle!,
                                backgroundColor: const Color(0xFFF3F4F6),
                              ),
                            if (difficulty != null)
                              ExamTag(
                                text: 'Độ khó: $difficulty',
                                backgroundColor: const Color(0xFFFFE4E1),
                                textColor: const Color(0xFFFF4500),
                              ),
                            ExamTag(
                              text: '# $point điểm',
                              backgroundColor: const Color(0xFFF3F4F6),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Tag chủ đề — xanh dương nhạt, hàng riêng
                        if (topic != null)
                          ExamTag(
                            text: 'Câu hỏi $topic',
                            backgroundColor: const Color(0xFFE0F2FE),
                            textColor: const Color(0xFF0369A1),
                          ),

                        const SizedBox(height: 20),

                        // ── ĐỀ BÀI ───────────────────────────────────────
                        // TODO: REPLACE WITH API — truyền data từ ExamCubit
                        QuestionCard(
                          questionText: ExamMockData.questionText,
                          imageAssetPath: ExamMockData.imageAssetPath,
                          videoUrl: ExamMockData.videoUrl,
                        ),

                        const SizedBox(height: 24),

                        // ── DANH SÁCH ĐÁP ÁN ─────────────────────────────
                        // TODO: REPLACE WITH API — lấy options từ ExamCubit
                        EssayInputField(
                          controller: _essayController,
                          enabled: isInteractable,
                          onChanged: (text) {
                            // Lấy text trực tiếp mỗi khi user gõ nếu cần xử lý realtime
                            print('Nội dung hiện tại: $text');
                          },
                        ),

                        SizedBox(height: 25),
                        // ── KHU VỰC NÚT BẤM CĂN GIỮA / XÁC NHẬN ──────────────────────────────────────
                        Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: !_isConfirming
                                ? SizedBox(
                                    key: const ValueKey('btn_answer'),
                                    width: 180,
                                    height: 48,
                                    child: ElevatedButton(
                                      // Nếu hết giờ hoặc ĐÃ NỘP BÀI rồi thì disable nút "Trả lời"
                                      onPressed: isInteractable
                                          ? () => setState(
                                              () => _isConfirming = true,
                                            )
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF4F46E5,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: Text(
                                        _isSubmitted
                                            ? "Đã nộp bài"
                                            : "Trả lời", // Thay đổi chữ hiển thị nếu đã nộp
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                : Row(
                                    key: const ValueKey('btn_confirm_group'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // NÚT HỦY
                                      SizedBox(
                                        width: 110,
                                        height: 44,
                                        child: OutlinedButton(
                                          onPressed: () {
                                            setState(
                                              () => _isConfirming = false,
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Color(0xFFD1D5DB),
                                              width: 1.5,
                                            ),
                                            foregroundColor: const Color(
                                              0xFF4B5563,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                            ),
                                          ),
                                          child: const Text(
                                            "Hủy",
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 16),

                                      // NÚT XÁC NHẬN
                                      SizedBox(
                                        width: 130,
                                        height: 44,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // 1. Kích hoạt trạng thái ĐÃ NỘP BÀI
                                            setState(() {
                                              _isSubmitted = true;
                                              _isConfirming =
                                                  false; // Thu cụm nút xác nhận lại thành nút mặc định
                                            });

                                            // 2. Hiển thị thông báo Toast / SnackBar cho người dùng biết
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Đã nộp bài tự luận thành công!',
                                                ),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );

                                            // 3. Xử lý đẩy data text ra API / Server của bạn tại đây
                                            String answerText =
                                                _essayController.text;
                                            print(
                                              "Dữ liệu nộp lên server: $answerText",
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF10B981,
                                            ),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                            ),
                                          ),
                                          child: const Text(
                                            "Xác nhận",
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        // Khoảng trống cuối — tránh bị cắt bởi bottom safe area
                        const SizedBox(height: 24),
                      ],
                    ),
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
