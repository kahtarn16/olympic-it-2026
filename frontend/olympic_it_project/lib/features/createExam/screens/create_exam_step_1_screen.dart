import 'package:flutter/material.dart';
import '../entities/exam.dart';
import '../widgets/exam_step_header.dart';
import 'create_exam_step_2_screen.dart';

class CreateExamStep1Screen extends StatefulWidget {
  const CreateExamStep1Screen({super.key});

  @override
  State<CreateExamStep1Screen> createState() =>
      _CreateExamStep1ScreenState();
}

class _CreateExamStep1ScreenState extends State<CreateExamStep1Screen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final targetController = TextEditingController();
  final subjectController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    targetController.dispose();
    subjectController.dispose();
    super.dispose();
  }

  Widget buildField(
    String label,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const ExamStepHeader(currentStep: 1),

              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  children: [
                    buildField(
                      "Đề tài kiểm tra",
                      "Nhập đề tài bài thi",
                      titleController,
                    ),
                    const SizedBox(height: 15),
                    buildField(
                      "Mô tả",
                      "Mô tả về đề thi",
                      descriptionController,
                    ),
                    const SizedBox(height: 15),
                    buildField(
                      "Đối tượng",
                      "Đối tượng của bài thi",
                      targetController,
                    ),
                    const SizedBox(height: 15),
                    buildField(
                      "Môn học",
                      "Nhập tên môn học hoặc ngành vào đây",
                      subjectController,
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (titleController.text.trim().isEmpty ||
                        descriptionController.text.trim().isEmpty ||
                        targetController.text.trim().isEmpty ||
                        subjectController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Vui lòng nhập đầy đủ thông tin"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Exam exam = Exam(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      subject: subjectController.text.trim(),
                      target: targetController.text.trim(),
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateExamStep2Screen(
                          exam: exam,
                          questions: [],
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Tiếp tục",
                    style: TextStyle(color: Colors.white),
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