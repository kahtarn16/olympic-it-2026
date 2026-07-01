import 'package:flutter/material.dart';
import 'package:olympic_it_project/exam/UI/data/exam_mock_data.dart';
import 'multiple_choice_exam_screen.dart';
import '../widgets/shared/responsive_layout.dart';

// Màn hình loading hiển thị thông tin câu hỏi trước khi vào thi
// SafeArea đầy đủ 4 cạnh — tránh notch, Dynamic Island, camera, home indicator
//
// TODO: REPLACE WITH API — nhận data từ server thay vì ExamMockData
class QuestionLoadingScreen extends StatefulWidget {
  const QuestionLoadingScreen({super.key});

  @override
  State<QuestionLoadingScreen> createState() => _QuestionLoadingScreenState();
}

class _QuestionLoadingScreenState extends State<QuestionLoadingScreen> {
  // TODO: REPLACE WITH API — các giá trị này lấy từ response server
  final int numberQuestion = ExamMockData.currentQuestion;
  final String? questionStyle = ExamMockData.questionStyle;
  final String? difficulty = ExamMockData.difficulty;
  final String? topic = ExamMockData.topic;

  @override
  void initState() {
    super.initState();
    _navigateToExamScreen();
  }

  // Chờ rồi tự động chuyển sang màn hình thi
  void _navigateToExamScreen() {
    Future.delayed(
      Duration(seconds: ExamMockData.loadingDurationSeconds),
      () {
        // Kiểm tra widget còn trong cây — tránh lỗi bộ nhớ
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              // TODO: REPLACE WITH API — truyền data câu hỏi vào screen
              builder: (context) => const MultipleChoiceExamScreen(),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Padding tự động theo kích thước màn hình
    final EdgeInsets padding = responsivePadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFF3B82F6),
      // SafeArea bảo vệ đủ 4 cạnh:
      // top    — notch, Dynamic Island, punch-hole camera
      // bottom — home indicator (iPhone), gesture navigation bar (Android)
      // left   — camera cạnh trên một số Android
      // right  — camera cạnh trên một số Android
      body: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        child: ResponsiveExamLayout(
          // Màu nền lề hai bên khớp với màu nền màn hình loading
          backgroundColor: const Color(0xFF3B82F6),
          child: Padding(
            padding: padding,
            child: Column(
              children: [
                const SizedBox(height: 100),

                // ── TIÊU ĐỀ SỐ CÂU HỎI ──────────────────────────────────
                Text(
                  'Câu hỏi $numberQuestion',
                  style: TextStyle(
                    // Font size responsive — lớn hơn trên tablet/desktop
                    fontSize: responsiveFontSize(
                      context,
                      phone: 22,
                      tablet: 26,
                      desktop: 30,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const Divider(
                  indent: 100,
                  endIndent: 100,
                  color: Colors.white,
                ),

                const SizedBox(height: 100),

                // ── 3 THẺ THÔNG TIN ──────────────────────────────────────
                // Dùng LayoutBuilder để tính kích thước thẻ theo màn hình
                LayoutBuilder(
  builder: (context, constraints) {
    // Giới hạn chiều rộng tối đa của toàn bộ cụm thẻ để không bị giãn quá to trên desktop
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Thẻ 1: Độ khó
          Expanded(
            flex: 10, // Tỷ lệ chiếm dụng không gian
            child: AspectRatio(
              aspectRatio: 1 / 1.4, // Giữ nguyên tỷ lệ cardHeight = cardWidth * 1.4
              child: _InfoCard(
                color: const Color(0xFF48ADEB),
                imagePath: 'assets/images/star.png',
                label: 'ĐỘ KHÓ',
                value: difficulty ?? '-',
              ),
            ),
          ),

          const SizedBox(width: 16), // Khoảng cách responsive an toàn

          // Thẻ 2: Loại câu hỏi — nổi lên cao hơn và rộng hơn tự động
          Expanded(
            flex: 11, // Rộng hơn 2 thẻ bên cạnh một chút nhờ tỷ lệ flex lớn hơn
            child: Transform.translate(
              offset: const Offset(0, -30), // Giảm offset một chút để an toàn trên màn hình nhỏ
              child: AspectRatio(
                aspectRatio: 1 / 1.4,
                child: _InfoCard(
                  color: const Color(0xFFB451E2),
                  imagePath: 'assets/images/question_mark.png',
                  label: 'LOẠI CÂU HỎI',
                  value: questionStyle ?? '-',
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Thẻ 3: Chủ đề
          Expanded(
            flex: 10,
            child: AspectRatio(
              aspectRatio: 1 / 1.4,
              child: _InfoCard(
                color: const Color(0xFF4963C9),
                imagePath: 'assets/images/ic_topic.png',
                label: 'CHỦ ĐỀ',
                value: topic ?? '-',
              ),
            ),
          ),
        ],
      ),
    );
  },
),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── WIDGET THẺ THÔNG TIN ─────────────────────────────────────────────────────
// Responsive: nhận width và height từ LayoutBuilder thay vì hardcode
class _InfoCard extends StatelessWidget {
  final Color color;
  final String imagePath;
  final String label;
  final String value;

  const _InfoCard({
    required this.color,
    required this.imagePath,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cardConstraints) {
        // Tính toán kích thước font chữ và icon động theo chiều rộng thực tế của thẻ
        final double currentWidth = cardConstraints.maxWidth;
        final double labelSize = (currentWidth * 0.11).clamp(10, 14);
        final double valueSize = (currentWidth * 0.13).clamp(11, 16);
        final double iconSize = (currentWidth * 0.3).clamp(24, 38);

        return Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Image.asset(
                    imagePath,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20), // Đẩy chữ xuống chút tránh đè icon
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: labelSize,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: valueSize,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}