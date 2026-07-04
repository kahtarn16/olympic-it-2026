import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:olympic_it_project/exam/UI/data/exam_mock_data.dart';
import 'package:olympic_it_project/exam/anti_cheat/cubit/anti_cheat_cubit.dart';
import 'package:olympic_it_project/exam/anti_cheat/widgets/violation_dialog.dart';
import '../widgets/shared/exam_header.dart';
import '../widgets/shared/exam_tag.dart';
import '../widgets/shared/question_card.dart';
import '../widgets/shared/responsive_layout.dart';
import '../widgets/multiple_choice/answer_option_tile.dart';

// Màn hình thi TRẮC NGHIỆM
// Anti-cheat: giám sát thoát app, kéo thanh thông báo, bong bóng chat
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

class _MultipleChoiceExamScreenState
    extends State<MultipleChoiceExamScreen> {
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

    // ✅ FIX: dùng addPostFrameCallback thay vì gọi context.read trực tiếp
    // initState() chưa có context hoàn chỉnh — gọi trực tiếp dễ crash
    // addPostFrameCallback đảm bảo widget đã render xong mới gọi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AntiCheatCubit>().startGuarding();
      }
    });
  }

  // TODO: REPLACE WITH API — xoá hàm này khi có CountdownCubit
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        // Hết giờ — dừng timer
        _timer?.cancel();
      }
    });
  }

  // Khoá bài khi vi phạm quá số lần — gọi từ BlocListener
  void _lockExam() {
    setState(() {
      remainingSeconds = 0; // đặt về 0 để isInteractable = false
    });
    _timer?.cancel();

    // Dừng giám sát anti-cheat
    context.read<AntiCheatCubit>().stopGuarding();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bài thi đã bị khoá do vi phạm quy định!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );

    // TODO: REPLACE WITH API — điều hướng sang màn hình bị cấm thi
  }

  @override
  void dispose() {
    _timer?.cancel();
    // ✅ FIX: KHÔNG gọi stopGuarding() ở đây
    // stopGuarding() đã được gọi trong _lockExam() khi vi phạm
    // hoặc khi thí sinh nộp bài — gọi lại trong dispose() là thừa
    // và có thể gây lỗi nếu Cubit đã bị đóng trước
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Padding tự động theo kích thước màn hình
    final EdgeInsets padding = responsivePadding(context);

    // Thí sinh chỉ tương tác được khi còn giờ
    final bool isInteractable = remainingSeconds > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AntiCheatCubit, AntiCheatState>(
        listener: (context, state) {

          // Thiết bị không an toàn (root/jailbreak) — hiện dialog chặn thi
          if (state is AntiCheatDeviceUnsafe) {
            showDialog(
              context: context,
              barrierDismissible: false, // không cho đóng bằng cách nhấn ra ngoài
              builder: (_) => AlertDialog(
                title: const Text('Thiết bị không đủ điều kiện'),
                content: Text(state.reason),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Thoát'),
                  ),
                ],
              ),
            );
          }

          // Phát hiện vi phạm (thoát app, kéo thanh thông báo...)
          if (state is AntiCheatViolationDetected) {
            if (state.isAutoSubmit) {
              // Vi phạm lần 3 — khoá bài ngay, không hỏi
              _lockExam();
            } else {
              // Vi phạm lần 1, 2 — hiện dialog cảnh báo
              ViolationDialog.show(
                context,
                log: state.log,
                totalViolations: state.totalViolations,
                onContinue: () {
                  // Thí sinh chọn tiếp tục — resume giám sát
                  context.read<AntiCheatCubit>().startGuarding();
                },
                onEnd: () {
                  // Thí sinh chọn kết thúc — khoá bài
                  _lockExam();
                },
              );
            }
          }

          // AntiCheatCubit tự emit Submitted sau 800ms khi vi phạm lần 3
          if (state is AntiCheatSubmitted) {
            _lockExam();
          }
        },
        child: SafeArea(
          // Bảo vệ đủ 4 cạnh:
          // top    — notch, Dynamic Island, punch-hole camera
          // bottom — home indicator (iPhone), gesture navigation bar (Android)
          // left   — camera cạnh trên một số Android
          // right  — camera cạnh trên một số Android
          top: true,
          bottom: true,
          left: true,
          right: true,
          child: ResponsiveExamLayout(
            child: Column(
              children: [
                // ── 1. HEADER CỐ ĐỊNH ──────────────────────────────────────
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

                // ── 2. NỘI DUNG CUỘN ĐƯỢC ──────────────────────────────────
                // Expanded giúp phần scroll chiếm hết không gian còn lại
                Expanded(
                  child: SingleChildScrollView(
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
                              isInteractable: isInteractable,
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
      ),
    );
  }

  // Xây dựng ô đáp án với logic chọn / khoá khi hết giờ hoặc vi phạm
  Widget _buildAnswerTile({
    required String label,
    required String content,
    required bool isInteractable,
  }) {
    final String currentState =
        selectedAnswer == label ? 'selected' : 'normal';

    return AnswerOptionTile(
      label: label,
      content: content,
      state: currentState,
      onTap: isInteractable && remainingSeconds > 0
          ? () => setState(() => selectedAnswer = label)
          : () {
              // Thông báo khi cố bấm vào đáp án đã bị khoá
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Bài thi đã bị khoá hoặc hết thời gian!'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 1),
                ),
              );
            },
    );
  }
}