import 'dart:async';
import 'package:flutter/material.dart';
import 'package:olympic_it_project/exam/UI/data/exam_mock_data.dart';
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
class MultipleChoiceExamScreen extends StatefulWidget {
  const MultipleChoiceExamScreen({super.key});

  @override
  State<MultipleChoiceExamScreen> createState() =>
      _MultipleChoiceExamScreenState();
}

class _MultipleChoiceExamScreenState extends State<MultipleChoiceExamScreen> {
  // TODO: REPLACE WITH API — lấy từ ExamCubit state
  int totalQuestions = ExamMockData.totalQuestions;
  int numberQuestion = ExamMockData.currentQuestion;
  String? questionStyle = ExamMockData.questionStyle;
  String? difficulty = ExamMockData.difficulty;
  String? topic = ExamMockData.topic;
  int point = ExamMockData.point;

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
                        ...ExamMockData.options.map(
                          (option) => _buildAnswerTile(
                            label: option['label']!,
                            content: option['content']!,
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

  // Xây dựng ô đáp án với logic chọn / khoá khi hết giờ
  Widget _buildAnswerTile({
    required String label,
    required String content,
  }) {
    final String currentState =
        selectedAnswer == label ? 'selected' : 'normal';

    return AnswerOptionTile(
      label: label,
      content: content,
      state: currentState,
      onTap: remainingSeconds > 0
          ? () => setState(() => selectedAnswer = label)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã hết thời gian, bạn không thể đổi đáp án!'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.orange,
                ),
              );
            },
    );
  }
}