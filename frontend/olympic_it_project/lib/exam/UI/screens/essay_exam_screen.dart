import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:olympic_it_project/exam/UI/data/exam_mock_data.dart';
import 'package:olympic_it_project/exam/UI/widgets/essay/essay_input_field.dart';
import 'package:olympic_it_project/exam/anti_cheat/cubit/anti_cheat_cubit.dart';
import 'package:olympic_it_project/exam/anti_cheat/widgets/violation_dialog.dart';
import '../widgets/shared/exam_header.dart';
import '../widgets/shared/exam_tag.dart';
import '../widgets/shared/question_card.dart';
import '../widgets/shared/responsive_layout.dart';

// Màn hình thi TỰ LUẬN
// Anti-cheat: giám sát thoát app, kéo thanh thông báo, bong bóng chat
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

  // Controller cho ô nhập tự luận
  final TextEditingController _essayController = TextEditingController();

  // Trạng thái xác nhận nộp bài — false: chưa bấm Trả lời, true: đang xác nhận
  bool _isConfirming = false;

  // Trạng thái đã nộp/khoá bài
  bool _isSubmitted = false;

  // TODO: REPLACE WITH API — lấy từ CountdownCubit
  int remainingSeconds = ExamMockData.remainingSeconds;

  // TODO: REPLACE WITH API — xoá Timer khi tích hợp CountdownCubit
  Timer? _timer;

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
    // ignore: avoid_print
    print('🔒 _lockExam() ESSAY ĐÃ ĐƯỢC GỌI');

    setState(() {
      _isSubmitted = true;     // đánh dấu đã nộp/khoá
      _isConfirming = false;   // thu cụm nút xác nhận lại
      remainingSeconds = 0;    // đặt về 0 để isInteractable = false
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
    _essayController.dispose(); // giải phóng controller tránh memory leak
    // ✅ FIX: KHÔNG gọi stopGuarding() ở đây
    // stopGuarding() đã được gọi trong _lockExam() khi vi phạm
    // hoặc khi thí sinh nhấn Xác nhận nộp bài
    // gọi lại trong dispose() là thừa và có thể gây lỗi
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Padding tự động theo kích thước màn hình
    final EdgeInsets padding = responsivePadding(context);

    // Thí sinh chỉ tương tác được khi còn giờ và chưa nộp/khoá bài
    final bool isInteractable = remainingSeconds > 0 && !_isSubmitted;

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
                  // ignore: avoid_print
                  print('✅ Bấm TIẾP TỤC - Essay');
                  // Thí sinh chọn tiếp tục — resume giám sát
                  context.read<AntiCheatCubit>().startGuarding();
                },
                onEnd: () {
                  // ignore: avoid_print
                  print('🔴 Bấm KẾT THÚC - Essay');
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

                          // ── Ô NHẬP TỰ LUẬN ───────────────────────────────
                          // enabled: false khi hết giờ hoặc đã nộp/khoá bài
                          EssayInputField(
                            controller: _essayController,
                            enabled: isInteractable,
                            onChanged: (text) {
                              // TODO: REPLACE WITH API — xử lý realtime nếu cần
                            },
                          ),

                          const SizedBox(height: 25),

                          // ── KHU VỰC NÚT BẤM ─────────────────────────────
                          // AnimatedSwitcher: chuyển mượt giữa nút "Trả lời"
                          // và cụm nút "Hủy / Xác nhận"
                          Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: !_isConfirming

                                  // Nút "Trả lời" — hiện mặc định
                                  ? SizedBox(
                                      key: const ValueKey('btn_answer'),
                                      width: 180,
                                      height: 48,
                                      child: ElevatedButton(
                                        // Disable khi hết giờ hoặc đã nộp/khoá
                                        onPressed: isInteractable
                                            ? () => setState(
                                                () => _isConfirming = true)
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF4F46E5),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: Text(
                                          // Đổi chữ khi đã khoá bài
                                          _isSubmitted ? 'Đã khoá bài' : 'Trả lời',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )

                                  // Cụm nút "Hủy / Xác nhận" — hiện khi bấm Trả lời
                                  : Row(
                                      key: const ValueKey('btn_confirm_group'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [

                                        // Nút Hủy — quay lại nút Trả lời
                                        SizedBox(
                                          width: 110,
                                          height: 44,
                                          child: OutlinedButton(
                                            onPressed: () => setState(
                                              () => _isConfirming = false,
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: Color(0xFFD1D5DB),
                                                width: 1.5,
                                              ),
                                              foregroundColor:
                                                  const Color(0xFF4B5563),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                              ),
                                            ),
                                            child: const Text(
                                              'Hủy',
                                              style:
                                                  TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 16),

                                        // Nút Xác nhận — nộp bài tự luận thành công
                                        SizedBox(
                                          width: 130,
                                          height: 44,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _isSubmitted = true;
                                                _isConfirming = false;
                                              });

                                              // Dừng giám sát vì thí sinh đã nộp bài
                                              context
                                                  .read<AntiCheatCubit>()
                                                  .stopGuarding();
                                              _timer?.cancel();

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Đã nộp bài tự luận thành công!',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  duration:
                                                      Duration(seconds: 2),
                                                ),
                                              );

                                              // TODO: REPLACE WITH API — gửi answerText lên server
                                              final String answerText =
                                                  _essayController.text;
                                              // ignore: avoid_print
                                              print(
                                                'Dữ liệu nộp lên server: $answerText',
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF10B981),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                              ),
                                            ),
                                            child: const Text(
                                              'Xác nhận',
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
      ),
    );
  }
}