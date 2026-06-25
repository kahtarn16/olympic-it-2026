import 'package:flutter/material.dart';

class MultipleChoiceExamScreen extends StatefulWidget {
  const MultipleChoiceExamScreen({super.key});

  @override
  State<MultipleChoiceExamScreen> createState() =>
      _MultipleChoiceExamScreenState();
}

class _MultipleChoiceExamScreenState
    extends State<MultipleChoiceExamScreen> {
  int totalQuestions = 12;
  int currentQuestion = 1;
  int remainingSeconds = 60;

  String? selectedAnswer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ExamHeader(
                currentQuestion: currentQuestion,
                totalQuestions: totalQuestions,
                remainingSeconds: remainingSeconds,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: const [
                        ExamTag(
                          text: "CÂU 3",
                          icon: "⚡",
                        ),
                        ExamTag(
                          text: "TRẮC NGHIỆM",
                        ),
                        ExamTag(
                          text: "Độ khó: Auth",
                        ),
                        ExamTag(
                          text: "30 điểm",
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Câu hỏi Tin học ứng dụng",
                      style: TextStyle(
                        color: Color(0xff60A5FA),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const QuestionCard(
                      questionText:
                          "Thí sinh hãy xem kỹ đoạn video ngắn mô tả thao tác sau đây. Trong kỹ năng sử dụng Excel, thao tác kéo chuột bằng đầu cổng đen ở góc ô như video trên được gọi là gì?",
                    ),

                    const SizedBox(height: 16),

                    _buildAnswerTile(
                      label: "A",
                      content:
                          "Kích hoạt tính năng kiểm tra lỗi chính tả",
                    ),

                    _buildAnswerTile(
                      label: "B",
                      content:
                          "Sử dụng tính năng tự động điền",
                    ),

                    _buildAnswerTile(
                      label: "C",
                      content:
                          "Chèn thêm các dòng trống mới và bảng tính",
                    ),

                    _buildAnswerTile(
                      label: "D",
                      content: "Tất cả đều sai",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerTile({
    required String label,
    required String content,
  }) {
    return AnswerOptionTile(
      label: label,
      content: content,
      isSelected: selectedAnswer == label,
      onTap: () {
        setState(() {
          selectedAnswer = label;
        });
      },
    );
  }
}

class ExamHeader extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final int remainingSeconds;

  const ExamHeader({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.remainingSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff3B82F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: currentQuestion
                        .toString()
                        .padLeft(2, '0'),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: "/$totalQuestions",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xff7C3AED),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              "$remainingSeconds",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExamTag extends StatelessWidget {
  final String text;
  final String? icon;

  const ExamTag({
    super.key,
    required this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffE5E7EB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Text(
              icon!,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          if (icon != null)
            const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class QuestionCard extends StatelessWidget {
  final String questionText;

  const QuestionCard({
    super.key,
    required this.questionText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          questionText,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 170,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius:
                BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 60,
            ),
          ),
        ),
      ],
    );
  }
}

class AnswerOptionTile extends StatelessWidget {
  final String label;
  final String content;
  final bool isSelected;
  final VoidCallback onTap;

  const AnswerOptionTile({
    super.key,
    required this.label,
    required this.content,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected
        ? const Color(0xff3B82F6)
        : Colors.grey.shade300;

    final Color backgroundColor = isSelected
        ? const Color(0xffEFF6FF)
        : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xff3B82F6)
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}