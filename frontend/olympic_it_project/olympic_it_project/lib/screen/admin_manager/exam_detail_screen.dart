import 'package:flutter/material.dart';
import 'package:olympic_it_project/dto/admin_manager/academic_year/academic_year_response.dart';
import 'package:olympic_it_project/dto/admin_manager/classes/classes_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/add_exam_question_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/add_participant_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_participant_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_question_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/remove_exam_question_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/update_exam_request.dart';
import 'package:olympic_it_project/dto/admin_manager/student/student_response.dart';
import 'package:olympic_it_project/service/academic_service.dart';
import 'package:olympic_it_project/service/classes_service.dart';
import 'package:olympic_it_project/service/exam_service.dart';
import 'package:olympic_it_project/service/student_service.dart';

class ExamDetailScreen extends StatefulWidget {
  final int examId;

  const ExamDetailScreen({super.key, required this.examId});

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  final ExamService _examService = ExamService();
  final StudentService _studentService = StudentService();
  final ClassService _classService = ClassService();
  final AcademicYearService _academicYearService = AcademicYearService();

  bool _isLoading = true;
  String? _errorMessage;
  ExamResponse? _exam;
  List<ExamQuestionResponse> _questions = [];
  List<ExamParticipantResponse> _participants = [];
  List<StudentResponse> _allStudents = [];
  List<ClassResponse> _classes = [];
  List<AcademicYearResponse> _years = [];
  int? _selectedYearId;
  int? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final exam = await _examService.getDetail(widget.examId);
      final questions = await _examService.getExamQuestions(widget.examId);
      final participants = await _examService.getExamParticipants(widget.examId);
      if (!mounted) return;
      setState(() {
        _exam = exam;
        _questions = questions;
        _participants = participants;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddQuestionDialog() async {
    final questionIdController = TextEditingController();
    final orderIndexController = TextEditingController(text: '1');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm câu hỏi vào đề thi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ID câu hỏi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: orderIndexController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Thứ tự hiển thị'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final questionId = int.tryParse(questionIdController.text.trim());
                final orderIndex = int.tryParse(orderIndexController.text.trim());
                if (questionId == null || orderIndex == null) return;
                try {
                  await _examService.addQuestion(
                    AddExamQuestionRequest(
                      examId: widget.examId,
                      questionId: questionId,
                      orderIndex: orderIndex,
                    ),
                  );
                  Navigator.pop(context);
                  await _loadDetail();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadParticipantLookupData() async {
    if (_allStudents.isNotEmpty && _classes.isNotEmpty && _years.isNotEmpty) return;

    try {
      final students = await _studentService.getAll();
      final classes = await _classService.getAll();
      final years = await _academicYearService.getAll();
      if (!mounted) return;
      setState(() {
        _allStudents = students;
        _classes = classes;
        _years = years;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được dữ liệu sinh viên: $e')),
      );
    }
  }

  Future<void> _addParticipantToExam(int userId) async {
    try {
      await _examService.addParticipant(
        AddParticipantRequest(
          examId: widget.examId,
          userId: userId,
        ),
      );
      await _loadDetail();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm thí sinh vào đề thi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _showAddParticipantDialog() async {
    await _loadParticipantLookupData();

    int? selectedYearId = _selectedYearId;
    int? selectedClassId = _selectedClassId;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filteredClasses = selectedYearId == null
                ? _classes
                : _classes.where((c) => c.academicYearId == selectedYearId).toList();

            final filteredStudents = _allStudents.where((student) {
              if (selectedYearId != null) {
                final studentClass = _classes.firstWhere(
                  (c) => c.id == student.classId,
                  orElse: () => ClassResponse(id: 0, className: '', academicYearId: 0),
                );
                if (studentClass.academicYearId != selectedYearId) {
                  return false;
                }
              }
              if (selectedClassId != null && student.classId != selectedClassId) {
                return false;
              }
              return true;
            }).toList();

            return AlertDialog(
              title: const Text('Chọn thí sinh vào đề thi'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedYearId,
                      decoration: const InputDecoration(labelText: 'Lọc theo khóa'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tất cả khóa')),
                        ..._years.map(
                          (year) => DropdownMenuItem(
                            value: year.id,
                            child: Text(year.yearName),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedYearId = value;
                          selectedClassId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedClassId,
                      decoration: const InputDecoration(labelText: 'Lọc theo lớp'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tất cả lớp')),
                        ...filteredClasses.map(
                          (klass) => DropdownMenuItem(
                            value: klass.id,
                            child: Text(klass.className),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedClassId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (filteredStudents.isEmpty)
                      const Text('Không tìm thấy sinh viên phù hợp.'),
                    if (filteredStudents.isNotEmpty)
                      SizedBox(
                        height: 320,
                        child: ListView.builder(
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(student.fullName),
                                subtitle: Text('${student.username} • ${student.className}'),
                                trailing: ElevatedButton(
                                  onPressed: () async {
                                    await _addParticipantToExam(student.id);
                                    if (context.mounted) Navigator.pop(context);
                                  },
                                  child: const Text('Thêm'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _removeQuestion(int questionId) async {
    try {
      await _examService.removeQuestion(
        RemoveExamQuestionRequest(
          examId: widget.examId,
          questionId: questionId,
        ),
      );
      await _loadDetail();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xoá câu hỏi khỏi đề thi')), 
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _startExam() async {
    try {
      await _examService.startExam(widget.examId);
      await _loadDetail();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đề thi đã bắt đầu')), 
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đề thi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetail,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _exam == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'addQuestion',
                  onPressed: _showAddQuestionDialog,
                  label: const Text('Thêm câu hỏi'),
                  icon: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'addParticipant',
                  onPressed: _showAddParticipantDialog,
                  label: const Text('Thêm thí sinh'),
                  icon: const Icon(Icons.person_add),
                ),
              ],
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Có lỗi xảy ra:\n$_errorMessage', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDetail,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_exam == null) {
      return const Center(child: Text('Không tìm thấy đề thi.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _exam!.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Trạng thái: ${_exam!.status}'),
                  Text('Người tạo: ${_exam!.createdBy}'),
                  Text('Ngày tạo: ${_exam!.createdAt}'),
                  Text('Trộn câu hỏi: ${_exam!.shuffleOption ? 'Có' : 'Không'}'),
                  const SizedBox(height: 12),
                  if (_exam!.status.toUpperCase() == 'WAITING')
                    ElevatedButton.icon(
                      onPressed: _startExam,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Bắt đầu đề thi'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Danh sách câu hỏi', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (_questions.isEmpty)
            const Text('Chưa có câu hỏi nào trong đề thi.'),
          ..._questions.map((question) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text('Câu hỏi #${question.questionId}'),
                subtitle: Text('${question.questionContent}\nThứ tự: ${question.orderIndex} | Điểm: ${question.questionScore}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeQuestion(question.questionId),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Text('Danh sách thí sinh', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (_participants.isEmpty)
            const Text('Chưa có thí sinh trong đề thi.'),
          ..._participants.map((participant) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(participant.userFullName),
                subtitle: Text('ID: ${participant.userId} | Trạng thái: ${participant.status} | Điểm: ${participant.score}'),
              ),
            );
          }),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
