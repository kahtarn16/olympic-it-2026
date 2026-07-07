import 'dart:async';

import 'package:flutter/material.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/question_detail_dto.dart';
import 'package:olympic_it_project/service/exam_service.dart';
import 'package:olympic_it_project/service/exam_stomp_service.dart';

class ExamRoomScreen extends StatefulWidget {
  final int examId;

  const ExamRoomScreen({super.key, required this.examId});

  @override
  State<ExamRoomScreen> createState() => _ExamRoomScreenState();
}

class _ExamRoomScreenState extends State<ExamRoomScreen>
    with WidgetsBindingObserver {
  final _stomp = ExamStompService();
  final _examService = ExamService();
  Timer? timer;
  String state = "WAITING";
  int currentIndex = 0;
  int total = 0;
  int remainingSeconds = 0;
  QuestionDetailDto? question;
  int? correctOptionId;
  int currentScore = 0;
  int? selectedOptionId;
  bool submitted = false;
  String? sampleAnswer;
  final TextEditingController essayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initExam();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    essayController.dispose();
    _stomp.disconnect();
    super.dispose();
  }

  Future<void> _initExam() async {
    try {
      await _connect();
    } catch (e) {
      debugPrint(e.toString());
    }
    await _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final res = await _examService.restoreExamState(widget.examId);

      setState(() {
        state = res.state;
        currentIndex = res.currentQuestionIndex ?? 0;
        total = res.totalQuestions;
        remainingSeconds = res.remainingSeconds.toInt();
        question = res.currentQuestion;
        correctOptionId = null;
        selectedOptionId = null;
        submitted = false;
        essayController.clear();
      });

      if (state == "PREVIEW" || state == "SHOW_QUESTION") {
        _startTimer();
      }
    } catch (e) {
      debugPrint("Restore lỗi: $e");
    }
  }

  Future<void> _connect() async {
    await _stomp.connect(
      examId: widget.examId,
      onMessage: (msg) {
        if (!mounted) return;

        try {
          final data = msg as Map<String, dynamic>;
          final type = data["type"];

          switch (type) {
            case "ROOM_READY":
              timer?.cancel();
              setState(() {
                state = "ROOM_READY";
                currentIndex = 0;
                total = 0;
                remainingSeconds = 0;
                question = null;
                correctOptionId = null;
                selectedOptionId = null;
                submitted = false;
                currentScore = 0;
                essayController.clear();
              });
              break;

            case "PREVIEW":
              final data = msg["data"];

              setState(() {
                state = "PREVIEW";
                currentIndex = data["index"];
                total = data["totalQuestions"];
                remainingSeconds = data["duration"];
                question = null;
                correctOptionId = null;
                selectedOptionId = null;
                submitted = false;
                essayController.clear();
              });
              _startTimer();
              break;

            case "SHOW_QUESTION":
              QuestionDetailDto? parsedQuestion;

              if (data["questionData"] != null) {
                parsedQuestion = QuestionDetailDto.fromJson(
                  data["questionData"],
                );
              }

              setState(() {
                state = "SHOW_QUESTION";
                currentIndex = data["currentQuestionIndex"] ?? 0;
                total = data["totalQuestions"] ?? 0;
                remainingSeconds = data["duration"] ?? 0;
                question = parsedQuestion;
                correctOptionId = null;
                selectedOptionId = null;
                submitted = false;
                essayController.clear();
              });
              _startTimer();
              break;

            case "SHOW_ANSWER":
              timer?.cancel();

              setState(() {
                state = "SHOW_ANSWER";
                correctOptionId = data["correctOptionId"];
                sampleAnswer = data["sampleAnswer"];
              });
              break;

            case "FINISH":
              timer?.cancel();
              setState(() {
                state = "FINISH";
              });
              break;
          }
        } catch (e) {
          debugPrint("Lỗi xử lý websocket: $e");
        }
      },
    );
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds <= 0) {
        t.cancel();
        return;
      }
      setState(() {
        remainingSeconds--;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
