import 'package:flutter/material.dart';
import 'answer_option_tile.dart'; // Import file chứa ô đáp án vừa tách ở trên

/// MÀN HÌNH CHÍNH: HIỂN THỊ CÂU HỎI TRẮC NGHIỆM ĐA LỰA CHỌN
class MultipleChoiceExamScreen extends StatefulWidget {
  const MultipleChoiceExamScreen({super.key});

  @override
  State<MultipleChoiceExamScreen> createState() => _MultipleChoiceExamScreenState();
}

class _MultipleChoiceExamScreenState extends State<MultipleChoiceExamScreen> {
  // --- Các biến quản lý trạng thái bài thi từ format của bạn ---
  int total_questions = 12;            
  int number_question = 1;            
  String? question_style = "TRẮC NGHIỆM"; 
  String? difficulty = "DỄ";           
  String? topic = "Lập trình cơ bản";   
  int point = 10;                     
  double time = 65;                   

  // --- LOGIC ĐÁP ÁN ĐÚNG / SAI ---
  final String correctAnswer = 'C';   // Giả định đáp án chính xác là 'C'
  String? selectedAnswer;             // Lưu đáp án người dùng click vào

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: SafeArea(
        top: false, 
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. THANH HEADER
              ExamHeader(
                currentQuestion: number_question,
                totalQuestions: total_questions,
                remainingSeconds: time.toInt(), 
              ),

              Padding(
                padding: const EdgeInsets.all(16.0), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. KHU VỰC CÁC TAG THÔNG TIN
                    Wrap(
                      spacing: 8,    
                      runSpacing: 8, 
                      children: [
                        ExamTag(text: 'CÂU $number_question', icon: '❓', backgroundColor: const Color(0xFFF3F4F6)),
                        if (question_style != null)
                          ExamTag(text: question_style!, backgroundColor: const Color(0xFFF3F4F6)),
                        if (difficulty != null)
                          ExamTag(
                            text: 'Độ khó: $difficulty', 
                            backgroundColor: const Color(0xFFFFE4E1), 
                            textColor: const Color(0xFFFF4500)
                          ),
                        ExamTag(text: '# $point điểm', backgroundColor: const Color(0xFFF3F4F6)),
                      ],
                    ),
                    const SizedBox(height: 12), 
                    
                    if (topic != null)
                      ExamTag(
                        text: 'Câu hỏi $topic', 
                        backgroundColor: const Color(0xFFE0F2FE), 
                        textColor: const Color(0xFF0369A1)
                      ),
                    
                    const SizedBox(height: 20),

                    // 3. KHỐI CÂU HỎI (Ảnh tự ẩn nếu không truyền link)
                    const QuestionCard(
                      questionText: 'Nhìn vào đoạn code Java bên dưới, kết quả xuất ra màn hình nào là ĐÚNG?',
                      imageAssetPath: 'assets/images/image_question.png', 
                    ),

                    const SizedBox(height: 24),

                    // 4. DANH SÁCH CÁC ĐÁP ÁN (Sử dụng widget AnswerOptionTile từ file riêng)
                    _buildAnswerTile(label: 'A', content: '2'),
                    _buildAnswerTile(label: 'B', content: '"11"'),
                    _buildAnswerTile(label: 'C', content: 'Lỗi biên dịch'),
                    _buildAnswerTile(label: 'D', content: 'Tất cả đều sai'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hàm phụ trợ (Helper) tính toán trạng thái Đúng/Sai để truyền vào UI
  Widget _buildAnswerTile({required String label, required String content}) {
    String currentState = 'normal'; 

    if (selectedAnswer != null) {
      if (label == selectedAnswer) {
        currentState = (selectedAnswer == correctAnswer) ? 'correct' : 'wrong';
      } else if (label == correctAnswer) {
        currentState = 'correct'; 
      }
    }

    return AnswerOptionTile(
      label: label,
      content: content,
      state: currentState, 
      onTap: () {
        if (selectedAnswer == null) {
          setState(() {
            selectedAnswer = label; 
          });
        }
      },
    );
  }
}

// ============================================================================
// CÁC THÀNH PHẦN WIDGET PHỤ TRỢ (GIỮ LẠI TRONG FILE SCREEN CHO GỌN)
// ============================================================================

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
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF3B82F6), 
        borderRadius: BorderRadius.all(Radius.circular(25)), 
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('❓ ', style: TextStyle(fontSize: 16)),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: currentQuestion.toString().padLeft(2, '0'), 
                        style: const TextStyle(color: Colors.orange),    
                      ),
                      TextSpan(
                        text: '/$totalQuestions',
                        style: const TextStyle(color: Colors.black),     
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 36, 4, 88).withOpacity(0.5), 
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$remainingSeconds',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
  final Color backgroundColor;
  final Color textColor;

  const ExamTag({
    super.key,
    required this.text,
    this.icon,
    required this.backgroundColor,
    this.textColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20), 
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, 
        children: [
          if (icon != null) ...[
            Text(icon!, style: const TextStyle(fontSize: 12)), 
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
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
  final String? imageAssetPath; 

  const QuestionCard({
    super.key,
    required this.questionText,
    this.imageAssetPath, 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questionText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.4, 
            ),
          ),
          if (imageAssetPath != null) ...[
            const SizedBox(height: 16), 
            ClipRRect(
              borderRadius: BorderRadius.circular(8), 
              child: Image.asset(
                imageAssetPath!, 
                width: double.infinity,
                fit: BoxFit.contain, 
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: const Color(0xFF2A2A2A),
                    alignment: Alignment.center,
                    child: const Text(
                      '[Ảnh minh họa code Java]',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}