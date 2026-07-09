import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenguard/flutter_screenguard.dart';
import 'package:olympic_it_project/core/api_client.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/question_detail_dto.dart';
import 'package:olympic_it_project/dto/profile/exam_session_dto.dart';
import 'package:olympic_it_project/screen/home/user_home_screen.dart';
import 'package:olympic_it_project/screen/student_exam/student_result_screen.dart';
import 'package:olympic_it_project/service/exam_service.dart';
import 'package:olympic_it_project/service/exam_stomp_service.dart';
import 'package:olympic_it_project/service/profile_student_service.dart';
import 'package:olympic_it_project/dto/profile/student_exam_result_response.dart';

class StudentExamScreen extends StatefulWidget {
  final int examId;
  final ExamSessionDto? session;

  const StudentExamScreen({super.key, required this.examId, this.session});

  @override
  State<StudentExamScreen> createState() => _StudentExamScreenState();
}

class _StudentExamScreenState extends State<StudentExamScreen>
    with WidgetsBindingObserver {
  final _studentExamService = ProfileStudentService();
  final _stomp = ExamStompService();
  final _examService = ExamService();
  final _profileService = ProfileStudentService();

  late final FlutterScreenguard _screenguard;
  StreamSubscription? _screenshotSub;
  StreamSubscription? _recordingSub;

  String state = "WAITING";
  int currentIndex = 0;
  int total = 0;
  int remainingSeconds = 0;
  QuestionDetailDto? question;
  int? correctOptionId;
  String? sampleAnswer;
  int currentScore = 0;
  int? selectedOptionId;
  bool submitted = false;
  bool submitting = false;

  String? previewType;
  String? previewLevel;
  int? previewScore;

  bool _confirmingAnswer = false;

  StudentExamResultResponse? examResult;
  bool loadingResult = false;

  final TextEditingController _essayController = TextEditingController();

  Timer? timer;

  bool get _isMcq =>
      question?.type == "MCQ_TEXT" || question?.type == "MCQ_MEDIA";
  bool get _isEssay =>
      question?.type == "ESSAY_TEXT" || question?.type == "ESSAY_MEDIA";

  bool get _isLocked =>
      submitted || submitting || _confirmingAnswer || selectedOptionId != null;

  String _typeLabel(String? type) {
    if (type == null) return "";
    if (type.startsWith("MCQ")) return "Trắc nghiệm";
    if (type.startsWith("ESSAY")) return "Tự luận";
    return type;
  }

  IconData _typeIcon(String? type) {
    if (type == null) return Icons.help_outline;
    if (type.startsWith("MCQ")) return Icons.checklist_rtl;
    if (type.startsWith("ESSAY")) return Icons.edit_note;
    return Icons.help_outline;
  }

  Color _typeColor(String? type) {
    if (type != null && type.startsWith("ESSAY")) {
      return Colors.purple;
    }
    return Colors.indigo;
  }

  String _levelLabel(String? level) {
    switch (level) {
      case "EASY":
        return "Dễ";
      case "MEDIUM":
        return "Trung bình";
      case "HARD":
        return "Khó";
      default:
        return level ?? "";
    }
  }

  Color _levelColor(String? level) {
    switch (level) {
      case "EASY":
        return Colors.green;
      case "MEDIUM":
        return Colors.orange;
      case "HARD":
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String? _fullImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '${ApiClient.host}$path';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screenguard = FlutterScreenguard();
    _initScreenGuard();
    _initExam();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _screenshotSub?.cancel();
    _recordingSub?.cancel();
    _screenguard.unregister();
    timer?.cancel();
    _essayController.dispose();
    _stomp.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState stateApp) {
    if (state == "SHOW_QUESTION") {
      if (stateApp == AppLifecycleState.paused ||
          stateApp == AppLifecycleState.inactive) {
        _sendAntiCheatViolation("LEAVE_APP");
      } else if (stateApp == AppLifecycleState.resumed) {
        _sendAntiCheatViolation("BACK_APP");
      }
    }
  }

  Future<void> _initScreenGuard() async {
    try {
      await _screenguard.initSettings(
        enableCapture: true,
        enableRecord: true,
        trackingLog: false,
      );

      _screenshotSub = _screenguard.onScreenshotCaptured.listen((event) {
        if (state == "SHOW_QUESTION") {
          _sendAntiCheatViolation("SCREENSHOT");
        }
      });

      _recordingSub = _screenguard.onScreenRecordingCaptured.listen((event) {
        if (state != "SHOW_QUESTION") return;
        final isRecording = event['isRecording'] as bool? ?? false;
        _sendAntiCheatViolation(isRecording ? "RECORD_START" : "RECORD_STOP");
      });
    } catch (e) {
      debugPrint("Không thể khởi tạo anti-cheat screen guard: $e");
    }
  }

  Future<void> _sendAntiCheatViolation(String violationType) async {
    try {
      await _examService.recordViolation(widget.examId, violationType);
    } catch (e) {
      debugPrint("Lỗi gửi anti-cheat ($violationType): $e");
    }
  }

  Future<void> _initExam() async {
    try {
      await _studentExamService.joinRoom(widget.examId);
    } catch (e) {
      debugPrint("Join exam lỗi: $e");
    }
    if (widget.session != null) {
      _applySession(widget.session!);
    }
    try {
      await _connect();
    } catch (e) {
      debugPrint(e.toString());
    }
    await _restoreSession();
  }

  void _applySession(ExamSessionDto session) {
    setState(() {
      state = session.state;
      currentIndex = session.currentQuestionIndex ?? 0;
      total = session.totalQuestions;
      remainingSeconds = session.remainingSeconds;
      question = session.currentQuestion;
      previewType = question?.type;
      previewLevel = question?.level;
      previewScore = question?.score;
      correctOptionId = null;
      sampleAnswer = null;
      selectedOptionId = null;
      submitted = false;
      submitting = false;
      _confirmingAnswer = false;
    });

    if (state == "PREVIEW" || state == "SHOW_QUESTION") {
      _startTimer();
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
                question = null;
                currentIndex = 0;
                total = 0;
                remainingSeconds = 0;
                correctOptionId = null;
                sampleAnswer = null;
                selectedOptionId = null;
                submitted = false;
                submitting = false;
                _confirmingAnswer = false;
                previewType = null;
                previewLevel = null;
                previewScore = null;
                _essayController.clear();
              });
              break;

            case "PREVIEW":
              final previewData = data["data"] as Map<String, dynamic>?;

              setState(() {
                state = "PREVIEW";
                currentIndex = previewData?["index"] ?? 0;
                total = previewData?["totalQuestions"] ?? 0;
                remainingSeconds = previewData?["duration"] ?? 5;
                previewType = previewData?["type"] as String?;
                previewLevel = previewData?["level"] as String?;
                previewScore = previewData?["score"] as int?;
                question = null;
                correctOptionId = null;
                sampleAnswer = null;
                selectedOptionId = null;
                submitted = false;
                submitting = false;
                _confirmingAnswer = false;
                _essayController.clear();
              });
              _startTimer();
              break;

            case "SHOW_QUESTION":
              QuestionDetailDto? parsedQuestion;
              if (data["questionData"] != null) {
                parsedQuestion = QuestionDetailDto.fromJson(
                  data["questionData"] as Map<String, dynamic>,
                );
              }

              setState(() {
                state = "SHOW_QUESTION";
                currentIndex = data["currentQuestionIndex"] ?? 0;
                total = data["totalQuestions"] ?? 0;
                remainingSeconds = data["duration"] ?? 0;
                question = parsedQuestion;
                previewType = parsedQuestion?.type ?? previewType;
                previewLevel = parsedQuestion?.level ?? previewLevel;
                previewScore = parsedQuestion?.score ?? previewScore;
                correctOptionId = null;
                sampleAnswer = null;
                selectedOptionId = null;
                submitted = false;
                submitting = false;
                _confirmingAnswer = false;
                _essayController.clear();
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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ExamResultScreen(examId: widget.examId),
                  ),
                );
              });
              break;

            case "RESET":
              timer?.cancel();
              setState(() {
                state = "WAITING";
                question = null;
                currentIndex = 0;
                total = 0;
                remainingSeconds = 0;
                correctOptionId = null;
                sampleAnswer = null;
                selectedOptionId = null;
                submitted = false;
                submitting = false;
                _confirmingAnswer = false;
                currentScore = 0;
                previewType = null;
                previewLevel = null;
                previewScore = null;
                _essayController.clear();
              });
              break;
          }
        } catch (e) {
          debugPrint("Lỗi xử lý WebSocket: $e");
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

  Future<void> _restoreSession() async {
    try {
      final res = await _examService.restoreExamState(widget.examId);

      setState(() {
        state = res.state;
        currentIndex = res.currentQuestionIndex ?? 0;
        total = res.totalQuestions;
        remainingSeconds = res.remainingSeconds.toInt();
        question = res.currentQuestion;
        previewType = question?.type;
        previewLevel = question?.level;
        previewScore = question?.score;
        correctOptionId = null;
        sampleAnswer = null;
        selectedOptionId = null;
        submitted = false;
      });

      if (state == "PREVIEW" || state == "SHOW_QUESTION") {
        _startTimer();
      } else if (state == "FINISH") {
        _loadExamResult();
      }
    } catch (e) {
      debugPrint("Restore lỗi: $e");
    }
  }

  Future<void> _loadExamResult() async {
    setState(() => loadingResult = true);
    try {
      final res = await _profileService.getExamResult(widget.examId);
      if (!mounted) return;
      setState(() {
        examResult = res;
        loadingResult = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingResult = false);
      debugPrint("Lỗi lấy kết quả thi: $e");
    }
  }

  bool _canSubmit() {
    if (state != "SHOW_QUESTION" ||
        submitted ||
        submitting ||
        _confirmingAnswer) {
      return false;
    }
    if (_isMcq) return selectedOptionId != null;
    if (_isEssay) return _essayController.text.trim().isNotEmpty;
    return false;
  }

  Future<void> _submitAnswer({int? optionId, String? answerText}) async {
    if (state != "SHOW_QUESTION" || submitted || submitting) return;

    if (optionId != null) {
      setState(() => selectedOptionId = optionId);
    }

    setState(() => submitting = true);

    try {
      final payload = <String, dynamic>{
        "selectedOptionId": optionId,
        "answerText": answerText,
      };

      final res = await _examService.submitAnswer(widget.examId, payload);

      if (!mounted) return;
      setState(() {
        submitted = true;
        submitting = false;
        currentScore = res.currentScore;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã gửi câu trả lời thành công!"),
          duration: Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint("submitAnswer lỗi (loại: ${e.runtimeType}): $e");

      setState(() {
        submitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Nộp bài thất bại: $e"),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: "Thử lại",
            textColor: Colors.white,
            onPressed: () {
              setState(() => submitted = false);
              _submitAnswer(optionId: optionId, answerText: answerText);
            },
          ),
        ),
      );
    }
  }

  Future<void> _confirmAndSubmitMcq(
    int optionId,
    String label,
    String contentText,
    bool hasImage,
  ) async {
    if (_isLocked) return;

    setState(() => _confirmingAnswer = true);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xác nhận đáp án"),
        content: Text(
          hasImage
              ? "Bạn chọn đáp án: ${label.isNotEmpty ? '$label' : ''}\n\n"
                    "Sau khi xác nhận sẽ không thể thay đổi. Bạn có chắc chắn không?"
              : "Bạn chọn: ${label.isNotEmpty ? '$label. ' : ''}$contentText\n\n"
                    "Sau khi xác nhận sẽ không thể thay đổi. Bạn có chắc chắn không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Chưa chắc chắn"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _submitAnswer(optionId: optionId);
      if (mounted) setState(() => _confirmingAnswer = false);
    } else {
      if (mounted) setState(() => _confirmingAnswer = false);
    }
  }

  Future<void> _confirmAndSubmitEssay() async {
    if (_confirmingAnswer || submitted || submitting) return;
    if (_essayController.text.trim().isEmpty) return;

    setState(() => _confirmingAnswer = true);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xác nhận nộp bài"),
        content: const Text(
          "Sau khi nộp, bạn sẽ không thể chỉnh sửa câu trả lời. Bạn có chắc chắn muốn nộp không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Chưa chắc chắn"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _submitAnswer(answerText: _essayController.text.trim());
    }
    if (mounted) setState(() => _confirmingAnswer = false);
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserHomeScreen()),
      (route) => false,
    );
  }

  // ================= UI: BADGE DÙNG CHUNG =================
  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
    double fontSize = 12,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.16), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ================= PREVIEW SCREEN (VIP STYLE) =================
  Widget _buildPreview() {
    // Ước lượng % thời gian còn lại để chạy vòng tròn tiến trình
    const previewTotal = 5; // trùng PREVIEW_DURATION_SECONDS bên server
    final progress = (remainingSeconds / previewTotal).clamp(0.0, 1.0);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon đầu, có hiệu ứng pulse nhẹ
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.05),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.withOpacity(0.15),
                    Colors.blue.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 42,
                color: Colors.indigo,
              ),
            ),
          ),

          const SizedBox(height: 22),

          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.indigo, Colors.blueAccent],
            ).createShader(bounds),
            child: const Text(
              "Chuẩn bị câu hỏi tiếp theo",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Câu ${currentIndex + 1} / $total",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Vòng tròn đếm ngược có progress ring
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1, end: progress),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 7,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        remainingSeconds <= 2
                            ? Colors.redAccent
                            : Colors.indigo,
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$remainingSeconds",
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: remainingSeconds <= 2
                            ? Colors.redAccent
                            : Colors.indigo,
                        height: 1,
                      ),
                    ),
                    Text(
                      "giây",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          if (previewType != null ||
              previewLevel != null ||
              previewScore != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _questionInfoBadges(
                type: previewType,
                level: previewLevel,
                score: previewScore,
                alignment: MainAxisAlignment.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _questionInfoBadges({
    required String? type,
    required String? level,
    required int? score,
    MainAxisAlignment alignment = MainAxisAlignment.start,
  }) {
    return Wrap(
      alignment: alignment == MainAxisAlignment.center
          ? WrapAlignment.center
          : WrapAlignment.start,
      spacing: 8,
      runSpacing: 8,
      children: [
        _badge(
          icon: _typeIcon(type),
          label: _typeLabel(type),
          color: _typeColor(type),
        ),
        if (level != null)
          _badge(
            icon: Icons.speed,
            label: "Độ khó: ${_levelLabel(level)}",
            color: _levelColor(level),
          ),
        if (score != null)
          _badge(
            icon: Icons.star_rounded,
            label: "$score điểm",
            color: Colors.amber.shade800,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isWaitingOrReady = state == "WAITING" || state == "ROOM_READY";

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Phòng thi trực tuyến"),
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$currentScore",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isWaitingOrReady && state != "FINISH") ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Câu ${currentIndex + 1} / $total",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      avatar: Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: remainingSeconds <= 5
                            ? Colors.red
                            : Colors.blue.shade700,
                      ),
                      label: Text("${remainingSeconds}s"),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: remainingSeconds <= 5
                            ? Colors.red
                            : Colors.blue.shade700,
                      ),
                      backgroundColor: remainingSeconds <= 5
                          ? Colors.red[50]
                          : Colors.blue[50],
                      side: BorderSide(
                        color: remainingSeconds <= 5
                            ? Colors.red.shade200
                            : Colors.blue.shade200,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (question != null)
                  _questionInfoBadges(
                    type: question!.type,
                    level: question!.level,
                    score: question!.score,
                  ),
                const Divider(height: 28),
              ],

              Expanded(child: _buildBody(isWaitingOrReady)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isWaitingOrReady) {
    if (isWaitingOrReady) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              "Đang chờ giảng viên bắt đầu cuộc thi...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    switch (state) {
      case "PREVIEW":
        return _buildPreview();
      case "SHOW_QUESTION":
        return _buildQuestion();
      case "SHOW_ANSWER":
        return _buildAnswer();
      case "FINISH":
        return _buildFinish();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _networkImage(
    String? rawUrl, {
    double? height,
    double width = double.infinity,
    BoxFit fit = BoxFit.cover,
  }) {
    final url = _fullImageUrl(rawUrl);
    if (url == null) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      width: width,
      child: Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            width: width,
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          height: height,
          width: width,
          color: Colors.grey.shade100,
          alignment: Alignment.center,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, color: Colors.grey),
              SizedBox(height: 4),
              Text(
                "Không tải được ảnh",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    if (question == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasQuestionImage =
        question!.imageUrl != null && question!.imageUrl!.trim().isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              question!.content,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),

          if (hasQuestionImage) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _networkImage(question!.imageUrl, height: 180),
            ),
          ],

          const SizedBox(height: 16),

          if (_isMcq) _buildMcqOptions(),
          if (_isEssay) _buildEssayInput(),
        ],
      ),
    );
  }

  Widget _buildMcqOptions() {
    return Column(
      children: question!.options.map((o) {
        final isSelected = selectedOptionId == o.id;
        final hasImage = o.imageUrl != null && o.imageUrl!.trim().isNotEmpty;
        final locked = _isLocked;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: InkWell(
            onTap: locked
                ? null
                : () => _confirmAndSubmitMcq(
                    o.id,
                    o.label,
                    o.contentText,
                    hasImage,
                  ),
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: (locked && !isSelected) ? 0.5 : 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.08)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (o.label.isNotEmpty) ...[
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          o.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: hasImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _networkImage(o.imageUrl, height: 120),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                o.contentText,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                    ),
                    if (isSelected && (submitting || _confirmingAnswer)) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEssayInput() {
    final locked = submitted || submitting || _confirmingAnswer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _essayController,
            enabled: !locked,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 1.5),
              ),
              hintText: "Nhập câu trả lời tự luận của bạn...",
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canSubmit() ? _confirmAndSubmitEssay : null,
            icon: (submitting || _confirmingAnswer)
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(submitted ? Icons.check_circle : Icons.send),
            label: Text(submitted ? "Đã gửi bài" : "Gửi bài tự luận"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswer() {
    if (question == null) {
      return const Center(
        child: Text(
          "Đã hết giờ trả lời. Đang chờ câu hỏi tiếp theo từ Admin...",
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              question!.content,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_isMcq)
            ...question!.options.map((o) {
              final isCorrect = o.id == correctOptionId;
              final isSelected = o.id == selectedOptionId;
              final hasImage =
                  o.imageUrl != null && o.imageUrl!.trim().isNotEmpty;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.withOpacity(0.12)
                        : isSelected
                        ? Colors.red.withOpacity(0.08)
                        : Colors.white,
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green
                          : (isSelected ? Colors.red : Colors.grey.shade300),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (o.label.isNotEmpty) ...[
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green
                                : (isSelected
                                      ? Colors.red
                                      : Colors.grey.shade200),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            o.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: (isCorrect || isSelected)
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: hasImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _networkImage(o.imageUrl, height: 120),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  o.contentText,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                      ),
                      if (isCorrect) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ],
                  ),
                ),
              );
            }),

          if (_isEssay) ...[
            if (sampleAnswer != null && sampleAnswer!.isNotEmpty) ...[
              const Text(
                "Đáp án mẫu:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(sampleAnswer!),
              ),
              const SizedBox(height: 12),
            ],
            if (_essayController.text.trim().isNotEmpty) ...[
              const Text(
                "Bài làm của bạn:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_essayController.text.trim()),
              ),
            ],
          ],

          const SizedBox(height: 20),
          Center(
            child: Text(
              "Đã hết giờ trả lời. Đang chờ câu hỏi tiếp theo từ Admin...",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinish() {
    if (loadingResult) {
      return const Center(child: CircularProgressIndicator());
    }

    if (examResult == null) {
      return const Center(
        child: Text(
          "Cuộc thi đã kết thúc!\nKhông thể tải kết quả.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
          const SizedBox(height: 12),
          const Text(
            "Cuộc thi đã kết thúc!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text(
                        "Điểm của bạn",
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "${examResult!.score}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        "Xếp hạng",
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "${examResult!.rank}/${examResult!.totalParticipants}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Bảng xếp hạng",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ...examResult!.leaderboard.map((lb) {
            final isMe = lb.rank == examResult!.rank;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue.withOpacity(0.08) : Colors.white,
                border: Border.all(
                  color: isMe ? Colors.blue : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      "#${lb.rank}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lb.name,
                      style: TextStyle(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    "${lb.score} điểm",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _goHome,
              icon: const Icon(Icons.home),
              label: const Text("Về màn hình chính"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
