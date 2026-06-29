import 'package:flutter/material.dart';

import '../entities/exam.dart';
import '../widgets/exam_step_header.dart';
import '../widgets/preview_question_card.dart';

class CreateExamStep4Screen extends StatelessWidget {
  final Exam exam;

  const CreateExamStep4Screen({
    super.key,
    required this.exam,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),

      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: ExamStepHeader(currentStep: 4),
            ),

            Expanded(
              child: exam.questions.isEmpty
                  ? const Center(
                      child: Text(
                        "Chưa có câu hỏi nào!",
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      itemCount: exam.questions.length,
                      itemBuilder: (context, index) {
                        return PreviewQuestionCard(
                          question: exam.questions[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            20,
          ),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                /// TODO:
                /// Upload ảnh/video Firebase Storage
                /// Sau đó lưu exam lên Firestore
              },
              child: const Text(
                "Hoàn thành",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}