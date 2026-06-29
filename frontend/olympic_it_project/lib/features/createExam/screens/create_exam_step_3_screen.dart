import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- BẮT BUỘC THÊM DÒNG NÀY ĐỂ DÙNG CHỈNH SỐ
import '../widgets/exam_step_header.dart';
import 'create_exam_step_4_screen.dart';
import '../entities/exam.dart';
import '../entities/question.dart';
import '../entities/exam.dart';

class CreateExamStep3Screen extends StatefulWidget {
  final Exam exam;
  final List<Question> questions;

  const CreateExamStep3Screen({
    super.key,
    required this.exam,
    required this.questions,
  });

  @override
  State<CreateExamStep3Screen> createState() => _CreateExamStep3ScreenState();
}

class _CreateExamStep3ScreenState extends State<CreateExamStep3Screen> {
  final durationController = TextEditingController();

  final scoreController = TextEditingController();

  final attemptController = TextEditingController();

  bool _showResultAfterSubmit = true;
  bool _shuffleQuestionsAndAnswers = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const ExamStepHeader(currentStep: 3),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. THỜI GIAN LÀM BÀI (CHỈ NHẬP SỐ) ---
                    const Text(
                      "Thời gian làm bài",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: TextField(
                              controller: durationController,
                              keyboardType:
                                  TextInputType.number, // Hiện bàn phím số
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly, // Chỉ cho phép gõ số số tự nhiên (0-9)
                              ],
                              decoration: InputDecoration(
                                hintText: "Nhập thời gian làm bài",
                                hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "phút",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- 2. TỔNG ĐIỂM (CHỈ NHẬP SỐ) ---
                    const Text(
                      "Tổng điểm",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 44,
                      child: TextField(
                        controller: scoreController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ), // Hỗ trợ nếu điểm có số thập phân (ví dụ: 9.5)
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ), // Chỉ cho phép nhập số và tối đa 1 dấu chấm thập phân
                        ],
                        decoration: InputDecoration(
                          hintText: "Nhập tổng điểm của bài thi",
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- 3. HIỂN THỊ KẾT QUẢ ---
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showResultAfterSubmit = !_showResultAfterSubmit;
                        });
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Row(
                        children: [
                          Icon(
                            _showResultAfterSubmit
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: _showResultAfterSubmit
                                ? Colors.blue
                                : Colors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Hiển thị kết quả sau khi nộp",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- 4. TRỘN CÂU HỎI VÀ ĐÁP ÁN ---
                    InkWell(
                      onTap: () {
                        setState(() {
                          _shuffleQuestionsAndAnswers =
                              !_shuffleQuestionsAndAnswers;
                        });
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Row(
                        children: [
                          Icon(
                            _shuffleQuestionsAndAnswers
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: _shuffleQuestionsAndAnswers
                                ? Colors.blue
                                : Colors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Trộn câu hỏi và đáp án",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- 5. SỐ LẦN THI (CHỈ NHẬP SỐ) ---
                    const Text(
                      "Số lần thi",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 44,
                      child: TextField(
                        controller: attemptController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly, // Chỉ cho phép nhập số nguyên
                        ],
                        decoration: InputDecoration(
                          hintText: "Nhập số lần thi",
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff3b82f6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (durationController.text.trim().isEmpty ||
                        scoreController.text.trim().isEmpty ||
                        attemptController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Vui lòng nhập đầy đủ thông tin"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateExamStep4Screen(
                          exam: widget.exam,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Tiếp tục",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
