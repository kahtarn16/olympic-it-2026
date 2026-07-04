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

class MultipleChoiceExamScreen extends StatefulWidget {
  const MultipleChoiceExamScreen({super.key});

  @override
  State<MultipleChoiceExamScreen> createState() => _MultipleChoiceExamScreenState();
}

class _MultipleChoiceExamScreenState extends State<MultipleChoiceExamScreen> {
  int totalQuestions = ExamMockData.totalQuestions;
  int numberQuestion = ExamMockData.currentQuestion;
  String? questionStyle = ExamMockData.questionStyle;
  String? difficulty = ExamMockData.difficulty;
  String? topic = ExamMockData.topic;
  int point = ExamMockData.point;

  int remainingSeconds = ExamMockData.remainingSeconds;
  Timer? _timer;
  String? selectedAnswer;

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
    setState(() {
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
    final bool isInteractable = remainingSeconds > 0 ;

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
                onContinue: () => context.read<AntiCheatCubit>().startGuarding(),
                onEnd: () {
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

                          ...ExamMockData.options.map(
                            (option) => _buildAnswerTile(
                              label: option['label']!,
                              content: option['content']!,
                              isInteractable: isInteractable,
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

    // Xây dựng ô đáp án với logic chọn / khoá khi hết giờ
  Widget _buildAnswerTile({
    required String label,
    required String content,
    required bool isInteractable,
  }) {
    final String currentState = selectedAnswer == label ? 'selected' : 'normal';

    return AnswerOptionTile(
      label: label,
      content: content,
      state: currentState,
      onTap: isInteractable && remainingSeconds > 0
          ? () => setState(() => selectedAnswer = label)
          : () {
              // Hiển thị thông báo khi cố bấm vào đáp án đã bị khoá
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bài thi đã bị khoá hoặc hết thời gian!'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 1),
                ),
              );
            },
    );
  }
}