import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:olympic_it_project/exam/UI/data/exam_mock_data.dart';
import 'package:olympic_it_project/exam/UI/widgets/essay/essay_input_field.dart';
import 'package:olympic_it_project/exam/cubit/anti_cheat_cubit.dart';
import 'package:olympic_it_project/exam/cubit/violation_dialog.dart';
import '../widgets/shared/exam_header.dart';
import '../widgets/shared/exam_tag.dart';
import '../widgets/shared/question_card.dart';
import '../widgets/shared/responsive_layout.dart';

class EssayExamScreen extends StatefulWidget {
  const EssayExamScreen({super.key});

  @override
  State<EssayExamScreen> createState() => _EssayExamScreenState();
}

class _EssayExamScreenState extends State<EssayExamScreen> {
  int totalQuestions = ExamMockData.totalQuestions;
  int numberQuestion = ExamMockData.currentQuestion;
  String? questionStyle = ExamMockData.questionStyle;
  String? difficulty = ExamMockData.difficulty;
  String? topic = ExamMockData.topic;
  int point = ExamMockData.point;

  final TextEditingController _essayController = TextEditingController();
  bool _isConfirming = false;
  bool _isSubmitted = false;
  int remainingSeconds = ExamMockData.remainingSeconds;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    context.read<AntiCheatCubit>().startGuarding();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _lockExam() {
    print("🔒 _lockExam() ESSAY ĐÃ ĐƯỢC GỌI"); // Debug
    setState(() {
      _isSubmitted = true;
      _isConfirming = false;
      remainingSeconds = 0;
    });
    _timer?.cancel();
    context.read<AntiCheatCubit>().stopGuarding();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bài thi đã bị khoá do vi phạm quy định!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    context.read<AntiCheatCubit>().stopGuarding();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = responsivePadding(context);
    final bool isInteractable = remainingSeconds > 0 && !_isSubmitted;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AntiCheatCubit, AntiCheatState>(
        listener: (context, state) {
          if (state is AntiCheatDeviceUnsafe) {
            showDialog(
              context: context,
              barrierDismissible: false,
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

          if (state is AntiCheatViolationDetected) {
            if (state.isAutoSubmit) {
              _lockExam();
            } else {
              ViolationDialog.show(
                context,
                log: state.log,
                totalViolations: state.totalViolations,
                onContinue: () {
                  print("✅ Bấm TIẾP TỤC - Essay");
                  context.read<AntiCheatCubit>().startGuarding();
                },
                onEnd: () {
                  print("🔴 Bấm KẾT THÚC - Essay");
                  _lockExam();
                },
              );
            }
          }

          if (state is AntiCheatSubmitted) {
            _lockExam();
          }
        },
        child: SafeArea(
          top: true,
          bottom: true,
          left: true,
          right: true,
          child: ResponsiveExamLayout(
            child: Column(
              children: [
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

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: padding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

                          if (topic != null)
                            ExamTag(
                              text: 'Câu hỏi $topic',
                              backgroundColor: const Color(0xFFE0F2FE),
                              textColor: const Color(0xFF0369A1),
                            ),

                          const SizedBox(height: 20),

                          QuestionCard(
                            questionText: ExamMockData.questionText,
                            imageAssetPath: ExamMockData.imageAssetPath,
                            videoUrl: ExamMockData.videoUrl,
                          ),

                          const SizedBox(height: 24),

                          EssayInputField(
                            controller: _essayController,
                            enabled: isInteractable,
                            onChanged: (text) {},
                          ),

                          const SizedBox(height: 25),

                          Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: !_isConfirming
                                  ? SizedBox(
                                      key: const ValueKey('btn_answer'),
                                      width: 180,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: isInteractable
                                            ? () => setState(() => _isConfirming = true)
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4F46E5),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                        ),
                                        child: Text(
                                          _isSubmitted ? "Đã khoá bài" : "Trả lời",
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
                                        SizedBox(
                                          width: 110,
                                          height: 44,
                                          child: OutlinedButton(
                                            onPressed: () => setState(() => _isConfirming = false),
                                            child: const Text("Hủy"),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        SizedBox(
                                          width: 130,
                                          height: 44,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _isSubmitted = true;
                                                _isConfirming = false;
                                              });
                                              context.read<AntiCheatCubit>().stopGuarding();
                                              _timer?.cancel();

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Đã nộp bài tự luận thành công!'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );

                                              String answerText = _essayController.text;
                                              print("Dữ liệu nộp lên server: $answerText");
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF10B981),
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text("Xác nhận"),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
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