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

class _ExamRoomScreenState extends State<ExamRoomScreen> with WidgetsBindingObserver {
  final _stomp = ExamStompService();
  final _examService = ExamService();

  String state = "WAITING";
  String statusText = "Đang kết nối...";
  int currentIndex = 0;
  int total = 0;
  int remainingSeconds = 0;
  QuestionDetailDto? currentQuestion;
  int? correctOptionId;
  String? sampleAnswer;
  int currentScore = 0; // Tổng điểm nếu cần
  String? errorMessage;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAdminRoom();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    _stomp.disconnect();
    super.dispose();
  }

  Future<void> _initAdminRoom() async {
    setState(() => statusText = "Đang kết nối phòng thi...");

    try {
      await _stomp.connect(
        examId: widget.examId,
        onMessage: (msg) {
          if (!mounted) return;
          _handleAdminMessage(msg);
        },
      );
    } catch (e) {
      setState(() {
        state = "ERROR";
        errorMessage = "WebSocket: $e";
      });
    }

    await _restoreSession();
  }

  void _handleAdminMessage(dynamic msg) {
    try {
      final data = msg as Map<String, dynamic>;
      final type = data["type"];

      switch (type) {
        case "ROOM_READY":
          setState(() => state = "ROOM_READY");
          break;

        case "PREVIEW":
          final d = data["data"];
          setState(() {
            state = "PREVIEW";
            currentIndex = d["index"];
            total = d["totalQuestions"];
            remainingSeconds = d["duration"];
          });
          _startTimer();
          break;

        case "SHOW_QUESTION":
          QuestionDetailDto? q;
          if (data["questionData"] != null) {
            q = QuestionDetailDto.fromJson(data["questionData"]);
          }
          setState(() {
            state = "SHOW_QUESTION";
            currentIndex = data["currentQuestionIndex"] ?? 0;
            total = data["totalQuestions"] ?? 0;
            remainingSeconds = data["duration"] ?? 0;
            currentQuestion = q;
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
          setState(() => state = "FINISH");
          break;
      }
    } catch (e) {
      debugPrint("Admin message error: $e");
    }
  }

  Future<void> _restoreSession() async {
    try {
      final res = await _examService.restoreExamState(widget.examId);
      setState(() {
        state = res.state;
        currentIndex = res.currentQuestionIndex ?? 0;
        total = res.totalQuestions;
        remainingSeconds = res.remainingSeconds.toInt();
        currentQuestion = res.currentQuestion;
      });

      if (state == "PREVIEW" || state == "SHOW_QUESTION") {
        _startTimer();
      }
    } catch (e) {
      setState(() {
        state = "ERROR";
        errorMessage = e.toString();
      });
    }
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds > 0 && mounted) {
        setState(() => remainingSeconds--);
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    );
  }
}