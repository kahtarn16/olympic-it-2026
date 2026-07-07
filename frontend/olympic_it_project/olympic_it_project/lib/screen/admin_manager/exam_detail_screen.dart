import 'package:flutter/material.dart';
import 'package:olympic_it_project/dto/admin_manager/academic_year/academic_year_response.dart';
import 'package:olympic_it_project/dto/admin_manager/category/category_response.dart';
import 'package:olympic_it_project/dto/admin_manager/classes/classes_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/add_exam_question_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/add_participant_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_details_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_participant_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/remove_exam_question_request.dart';
import 'package:olympic_it_project/dto/admin_manager/question/question_response.dart';
import 'package:olympic_it_project/screen/admin_manager/exam_room_screen.dart';
import 'package:olympic_it_project/service/academic_service.dart';
import 'package:olympic_it_project/service/category_service.dart';
import 'package:olympic_it_project/service/classes_service.dart';
import 'package:olympic_it_project/service/exam_service.dart';
import 'package:olympic_it_project/service/question_service.dart';
import 'package:olympic_it_project/dto/admin_manager/student/student_response.dart';
import 'package:olympic_it_project/service/student_service.dart';

class ExamDetailScreen extends StatefulWidget {
  final int examId;
  const ExamDetailScreen({super.key, required this.examId});

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  final _studentService = StudentService();

  List<StudentResponse> availableStudents = [];
  StudentResponse? selectedStudent;
  final _examService = ExamService();
  final _questionService = QuestionService();
  final _categoryService = CategoryService();

  // ================= DATA =================
  ExamDetailsResponse? exam;

  List<CategoryResponse> categories = [];
  List<QuestionResponse> questions = [];

  List<AcademicYearResponse> academicYears = [];
  List<ClassResponse> classes = [];

  List<ExamParticipantResponse> students = [];
  List<ExamParticipantResponse> filteredStudents = [];

  // ================= SELECTED =================
  CategoryResponse? selectedCategory;
  QuestionResponse? selectedQuestion;

  AcademicYearResponse? selectedYear;
  ClassResponse? selectedClass;

  final TextEditingController _orderController = TextEditingController();

  // ================= LOADING =================
  bool loading = false;
  bool loadingQuestions = false;
  bool loadingStudents = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadExam(),
      _loadCategories(),
      _loadAcademicYears(),
      _loadStudents(),
      _loadStudentsForSelect(),
    ]);
  }

  Future<void> _loadStudentsForSelect() async {
    try {
      final res = await _studentService.getAll();
      setState(() {
        availableStudents = res;
      });
    } catch (e) {
      _showError("Không load được danh sách sinh viên");
    }
  }

  // ================= EXAM =================
  Future<void> _loadExam() async {
    setState(() => loading = true);

    try {
      final res = await _examService.getDetail(widget.examId);
      exam = res;
    } catch (e) {
      _showError("Không tải được đề thi");
    }

    if (mounted) setState(() => loading = false);
  }

  // ================= CATEGORIES =================
  Future<void> _loadCategories() async {
    try {
      final res = await _categoryService.getAll();
      setState(() => categories = res);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // ================= ACADEMIC + CLASS =================
  Future<void> _loadAcademicYears() async {
    try {
      final res = await AcademicYearService().getAll();
      setState(() => academicYears = res);
    } catch (e) {
      _showError("Không load được khóa");
    }
  }

  Future<void> _loadClassesByYear(int yearId) async {
    try {
      final res = await ClassService().getAll(academicYearId: yearId);

      setState(() {
        classes = res;
        selectedClass = null;
      });
    } catch (e) {
      _showError("Không load được lớp");
    }
  }

  // ================= QUESTIONS =================
  Future<void> _loadQuestionsByCategory(int categoryId) async {
    setState(() => loadingQuestions = true);

    try {
      final res = await _questionService.getAll(
        page: 0,
        size: 100,
        categoryId: categoryId,
      );

      setState(() {
        questions = res.items;
        selectedQuestion = null;
      });
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() => loadingQuestions = false);
  }

  Future<void> _addQuestion() async {
    final order = int.tryParse(_orderController.text);

    if (selectedQuestion == null || order == null) {
      _showError("Thiếu dữ liệu");
      return;
    }

    try {
      await _examService.addQuestion(
        AddExamQuestionRequest(
          examId: widget.examId,
          questionId: selectedQuestion!.id,
          orderIndex: order,
        ),
      );

      Navigator.pop(context);
      await _loadExam();

      _showSuccess("Thêm câu hỏi thành công");
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _removeQuestion(int questionId) async {
    try {
      await _examService.removeQuestion(
        RemoveExamQuestionRequest(
          examId: widget.examId,
          questionId: questionId,
        ),
      );

      await _loadExam();
      _showSuccess("Xóa câu hỏi thành công");
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _loadStudents() async {
    setState(() => loadingStudents = true);

    try {
      final res = await _examService.getExamParticipants(widget.examId);
      students = res;

      setState(() {
        filteredStudents = res;
      });
    } catch (e) {
      _showError("Không load được sinh viên");
    }

    setState(() => loadingStudents = false);
  }

  void _filterStudents() {
    List<ExamParticipantResponse> result = students;

    if (selectedClass != null) {
      result = result
          .where((s) => s.className == selectedClass!.className)
          .toList();
    }

    setState(() => filteredStudents = result);
  }

  

  Future<void> _removeStudent(int userId) async {
    try {
      await _examService.removeParticipant(widget.examId, userId);

      await _loadStudents();
      _showSuccess("Xóa sinh viên thành công");
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _goToExamRoom() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExamRoomScreen(examId: widget.examId)),
    );
  }

  // ================= DIALOG ADD QUESTION =================
  void _showAddDialog() {
    selectedCategory = null;
    selectedQuestion = null;
    _orderController.clear();
    questions = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Thêm câu hỏi"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<CategoryResponse>(
                    value: selectedCategory,
                    items: categories
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.name)),
                        )
                        .toList(),
                    onChanged: (v) async {
                      setStateDialog(() => selectedCategory = v);

                      if (v != null) {
                        await _loadQuestionsByCategory(v.id);
                        setStateDialog(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  loadingQuestions
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<QuestionResponse>(
                          value: selectedQuestion,
                          items: questions
                              .map(
                                (q) => DropdownMenuItem(
                                  value: q,
                                  child: Text(q.content),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setStateDialog(() => selectedQuestion = v),
                        ),

                  TextField(
                    controller: _orderController,
                    decoration: const InputDecoration(labelText: "Thứ tự"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: _addQuestion,
                  child: const Text("Thêm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddStudentDialog() {
    selectedYear = null;
    selectedClass = null;
    selectedStudent = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Thêm sinh viên vào đề thi"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ================= KHÓA =================
                  DropdownButtonFormField<AcademicYearResponse>(
                    value: selectedYear,
                    decoration: const InputDecoration(labelText: "Khóa"),
                    items: academicYears
                        .map(
                          (y) => DropdownMenuItem(
                            value: y,
                            child: Text(y.yearName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) async {
                      setStateDialog(() {
                        selectedYear = v;
                        selectedClass = null;
                        selectedStudent = null;
                        classes = [];
                      });

                      if (v != null) {
                        await _loadClassesByYear(v.id);
                        setStateDialog(() {});
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  // ================= LỚP =================
                  DropdownButtonFormField<ClassResponse>(
                    value: selectedClass,
                    decoration: const InputDecoration(labelText: "Lớp"),
                    items: classes
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.className),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setStateDialog(() {
                        selectedClass = v;
                        selectedStudent = null;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // ================= SINH VIÊN =================
                  DropdownButtonFormField<StudentResponse>(
                    value: selectedStudent,
                    decoration: const InputDecoration(labelText: "Sinh viên"),
                    items: availableStudents
                        .where(
                          (s) =>
                              selectedClass == null ||
                              s.className == selectedClass!.className,
                        )
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setStateDialog(() {
                        selectedStudent = v;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedStudent == null) return;

                    await _examService.addParticipant(
                      AddParticipantRequest(
                        examId: widget.examId,
                        userId: selectedStudent!.id,
                      ),
                    );

                    Navigator.pop(context);

                    await _loadStudents();
                    _filterStudents();

                    _showSuccess("Thêm sinh viên thành công");
                  },
                  child: const Text("Thêm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= UI =================
  Widget _buildInfoCard() {
    final e = exam!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const Divider(),

            _row("Trạng thái", e.status),
            _row("Người tạo", e.createdBy),
            _row("Ngày tạo", e.createdAt),

            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Câu hỏi",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Thêm"),
                ),
              ],
            ),

            ...e.questions.map(
              (q) => ListTile(
                title: Text(q.question.content),
                subtitle: Text("Order: ${q.orderIndex}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeQuestion(q.question.id),
                ),
              ),
            ),

            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sinh viên",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddStudentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Thêm"),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ...filteredStudents.map(
              (s) => ListTile(
                title: Text(s.fullName),
                subtitle: Text(s.className),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeStudent(s.userId),
                ),
              ),
            ),
            const Divider(),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ================= 1. TẠO PHÒNG =================
                ElevatedButton(
                  onPressed: exam!.status == "WAITING"
                      ? () async {
                          try {
                            await _examService.createRoom(widget.examId);
                            await _loadExam();

                            _goToExamRoom();
                          } catch (e) {
                            _showError(e.toString());
                          }
                        }
                      : null,
                  child: const Text("Tạo phòng"),
                ),

                // ================= 2. VÀO LẠI PHÒNG =================
                ElevatedButton(
                  onPressed:
                      (exam!.status == "ROOM_READY" ||
                          exam!.status == "RUNNING")
                      ? () {
                          _goToExamRoom();
                        }
                      : null,
                  child: const Text("Vào lại phòng"),
                ),

                // ================= 3. THI LẠI =================
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: exam!.status == "FINISHED"
                      ? () async {
                          try {
                            await _examService.resetExam(widget.examId);
                            await _loadExam();
                          } catch (e) {
                            _showError(e.toString());
                          }
                        }
                      : null,
                  child: const Text("Thi lại"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String a, String b) => Row(children: [Text("$a: "), Text(b)]);

  void _showError(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _showSuccess(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết đề thi")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : exam == null
          ? const Center(child: Text("Không có dữ liệu"))
          : SingleChildScrollView(child: _buildInfoCard()),
    );
  }
}
