import 'package:flutter/material.dart';
import 'package:olympic_it_project/exam/multiple_choice_exam_screen.dart';

class QuestionLoadingScreen extends StatefulWidget {
  const QuestionLoadingScreen({super.key});

  @override
  State<QuestionLoadingScreen> createState() => _QuestionLoadingScreenState();
}

class _QuestionLoadingScreenState extends State<QuestionLoadingScreen> {
  int number_question = 1;
  String? question_style = "TRẮC NGHIỆM";
  String? difficulty = "DỄ";
  String? topic = "LẬP TRÌNH CƠ BẢN";

  @override
  void initState() {
    super.initState(); {
      // Gọi hàm đếm ngược thời gian ngay khi màn hình vừa được khởi tạo
      _navigateToExamScreen();
    }
  }
  void _navigateToExamScreen() {
    // Giả định thời gian loading là 3 giây (đổi tùy ý ở phần Duration)
    Future.delayed(const Duration(seconds: 5), () {
      // Kiểm tra nếu Widget vẫn còn nằm trong cây thư mục (tránh lỗi bộ nhớ)
      if (mounted) {
        // Chuyển sang màn hình câu hỏi và XÓA luôn màn hình Loading khỏi Stack
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MultipleChoiceExamScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
      backgroundColor: const Color(0xFF3B82F6),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 130),
            Text(
              "Câu hỏi $number_question",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Divider(
              indent: 150, 
              endIndent: 150, 
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
            SizedBox(height: 150),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              // crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 120,
                  height: 165,
                  decoration: BoxDecoration(
                    color: const Color(0xFF48ADEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsetsGeometry.only(top: 5),
                          child: Image.asset(
                            'assets/images/star.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "ĐỘ KHÓ",
                              style: TextStyle(color: Colors.grey[300]),
                            ),
                            Text(
                              "$difficulty",
                              style: TextStyle(color: Colors.white,fontSize: 17)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Transform.translate(
                  offset: const Offset(0, -50),
                  child: Container(
                    width: 130,
                    height: 165, // Cao hơn 1 nửa (100 * 1.5 = 150)
                    decoration: BoxDecoration(
                      color: const Color(0xFFB451E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsetsGeometry.only(top: 5),
                            child: Image.asset(
                              'assets/images/question_mark.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "LOẠI CÂU HỎI",
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                              Text(
                                "$question_style",
                                style: TextStyle(color: Colors.white,fontSize: 17),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 20),
                Container(
                  width: 120,
                  height: 165,
                  decoration: BoxDecoration(
                    color: Color(0xFF4963C9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsetsGeometry.only(top: 5),
                            child: Image.asset(
                              'assets/images/ic_topic.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "CHỦ ĐỀ",
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                              Text(
                                "$topic",
                                style: TextStyle(color: Colors.white,fontSize: 17),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
    );
  }
}
