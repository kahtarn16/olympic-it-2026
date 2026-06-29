import 'package:flutter/material.dart';
import '../widgets/exam_step_header.dart';
import 'create_exam_step_3_screen.dart';
import '../entities/exam.dart';
import '../entities/question.dart';
import '../entities/answer.dart';
import '../entities/question_type.dart';
import '../entities/difficulty.dart';
import '../widgets/question_card.dart';

class CreateExamStep2Screen extends StatefulWidget {
  final Exam exam;
  final List<Question> questions;

  const CreateExamStep2Screen({
    super.key,
    required this.exam,
    required this.questions,
  });

  @override
  State<CreateExamStep2Screen> createState() =>
      _CreateExamStep2ScreenState();
}

class _CreateExamStep2ScreenState
    extends State<CreateExamStep2Screen> {

  late List<Question> _questions;

  @override
  void initState() {
    super.initState();

    if (widget.exam.questions.isEmpty) {
      _questions = [
        Question(
          order: 1,
          type: QuestionType.singleChoice,
          content: "",
          difficulty: Difficulty.medium,
          answers: [
            Answer(id: "A", content: ""),
            Answer(id: "B", content: ""),
            Answer(id: "C", content: ""),
            Answer(id: "D", content: ""),
          ],
          correctAnswerIds: [],
        ),
      ];
    } else {
      _questions = widget.exam.questions;
    }
  }

  //--------------------------------------------
  // Thêm câu hỏi
  //--------------------------------------------
  void _addQuestion() {
    setState(() {
      _questions.add(
        Question(
          order: _questions.length + 1,
          type: QuestionType.singleChoice,
          content: "",
          difficulty: Difficulty.medium,
          answers: [
            Answer(id: "A", content: ""),
            Answer(id: "B", content: ""),
            Answer(id: "C", content: ""),
            Answer(id: "D", content: ""),
          ],
          correctAnswerIds: [],
        ),
      );
    });
  }

  //--------------------------------------------
  // Xóa câu hỏi
  //--------------------------------------------
  void _deleteQuestion(int index) {

    if (_questions.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Phải có ít nhất 1 câu hỏi"),
        ),
      );
      return;
    }

    setState(() {

      _questions.removeAt(index);

      for (int i = 0; i < _questions.length; i++) {
        _questions[i].order = i + 1;
      }

    });
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [

            const ExamStepHeader(currentStep: 2),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _questions.length,
                itemBuilder: (context, index) {

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: QuestionCard(

                      question: _questions[index],

                      onDelete: () {
                        _deleteQuestion(index);
                      },

                      showAddButton:
                          index == _questions.length - 1,

                      onAddNext: () {
                        _addQuestion();
                      },

                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xff3b82f6),

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  onPressed: () {
                    if (_questions.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Bạn phải thêm ít nhất 1 câu hỏi"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateExamStep3Screen(
                          exam: widget.exam,
                          questions: _questions,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Tiếp tục",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}