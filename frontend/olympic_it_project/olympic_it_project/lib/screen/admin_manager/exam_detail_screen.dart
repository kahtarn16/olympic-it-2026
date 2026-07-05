import 'package:flutter/material.dart';
import 'package:olympic_it_project/dto/admin_manager/academic_year/academic_year_response.dart';
import 'package:olympic_it_project/dto/admin_manager/category/category_response.dart';
import 'package:olympic_it_project/dto/admin_manager/classes/classes_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/add_exam_question_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/add_participant_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_participant_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_question_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/remove_exam_question_request.dart';
import 'package:olympic_it_project/dto/admin_manager/question/question_response.dart';
import 'package:olympic_it_project/dto/admin_manager/student/student_response.dart';
import 'package:olympic_it_project/service/academic_service.dart';
import 'package:olympic_it_project/service/category_service.dart';
import 'package:olympic_it_project/service/classes_service.dart';
import 'package:olympic_it_project/service/exam_service.dart';
import 'package:olympic_it_project/service/question_service.dart';
import 'package:olympic_it_project/service/student_service.dart';
import 'package:olympic_it_project/utils/error_snackbar.dart';

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
  final QuestionService _questionService = QuestionService();
  final _categoryService = CategoryService();

  List<QuestionResponse> _allQuestions = [];
  int? _selectedQuestionId;
  int _orderIndex = 1;
  List<CategoryResponse> _categories = [];
  int? _selectedCategoryId;

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

  Future<void> _loadCategories() async {
    final data = await _categoryService.getAll();
    setState(() => _categories = data);
  }

  Future<void> _loadAllQuestions() async {
    try {
      final res = await _questionService.getAll(page: 0, size: 100, categoryId: _selectedCategoryId);
      setState(() => _allQuestions = res.items);
    } catch (e) {
      ErrorSnackbar.showError(context, e);
    }
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

  // ✨ Dialog thêm câu hỏi: Khởi tạo layout to rõ ràng, nút Thêm hoành tráng
  Future<void> _showAddQuestionDialog() async {
    await _loadCategories();
    await _loadAllQuestions();
    _selectedQuestionId = null;
    _orderIndex = 1;

    if (!mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.library_add_rounded, color: Color(0xFF2563EB), size: 24),
                            SizedBox(width: 12),
                            Text('Thêm câu hỏi vào đề', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: InputDecoration(labelText: 'Danh mục câu hỏi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                          items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (value) async {
                            setStateDialog(() => _selectedCategoryId = value);
                            await _loadAllQuestions();
                            setStateDialog(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _selectedQuestionId,
                          decoration: InputDecoration(labelText: 'Chọn nội dung câu hỏi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                          items: _allQuestions.map((q) => DropdownMenuItem(value: q.id, child: Text(q.content, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (value) => setStateDialog(() => _selectedQuestionId = value),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Thứ tự hiển thị câu hỏi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                          onChanged: (v) => _orderIndex = int.tryParse(v) ?? 1,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                onPressed: () => Navigator.pop(context),
                                child: const Text("HỦY BỎ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                onPressed: () async {
                                  if (_selectedQuestionId == null) return;
                                  try {
                                    await _examService.addQuestion(AddExamQuestionRequest(examId: widget.examId, questionId: _selectedQuestionId!, orderIndex: _orderIndex));
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    await _loadDetail();
                                  } catch (e) {
                                    ErrorSnackbar.showError(context, e);
                                  }
                                },
                                child: const Text("THÊM CÂU HỎI", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
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
      ErrorSnackbar.showError(context, e);
    }
  }

  Future<void> _addParticipantToExam(int userId) async {
    try {
      await _examService.addParticipant(AddParticipantRequest(examId: widget.examId, userId: userId));
      await _loadDetail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm thí sinh thành công!')));
    } catch (e) {
      if (!mounted) return;
      ErrorSnackbar.showError(context, e);
    }
  }

  // ✨ Dialog chọn thí sinh: Bộ chọn và danh sách Card kèm nút "THÊM" bự, rõ
  Future<void> _showAddParticipantDialog() async {
    await _loadParticipantLookupData(); //

    int? selectedYearId = _selectedYearId; //
    int? selectedClassId = _selectedClassId; //

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent, // Để làm mờ nền phía sau góc bo tròn
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                final filteredClasses = selectedYearId == null
                    ? _classes //
                    : _classes //
                        .where((c) => c.academicYearId == selectedYearId)
                        .toList();

                final filteredStudents = _allStudents.where((student) { //
                  if (selectedYearId != null) {
                    final studentClass = _classes.firstWhere( //
                      (c) => c.id == student.classId,
                      orElse: () => ClassResponse(id: 0, className: '', academicYearId: 0),
                    );
                    if (studentClass.academicYearId != selectedYearId) {
                      return false;
                    }
                  }
                  if (selectedClassId != null && student.classId != selectedClassId) { //
                    return false;
                  }
                  return true;
                }).toList();

                return Column(
                  mainAxisSize: MainAxisSize.min, // Giúp Dialog co khít theo chiều dọc nội dung thực tế
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tiêu đề Dialog tùy biến đẹp hơn
                    Row(
                      children: const [
                        Icon(Icons.person_add_rounded, color: Color(0xFF2563EB), size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Chọn thí sinh vào đề thi',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Bộ lọc Khóa
                    DropdownButtonFormField<int>(
                      value: selectedYearId,
                      decoration: InputDecoration(
                        labelText: 'Lọc theo khóa',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tất cả khóa')), //
                        ..._years.map((year) => DropdownMenuItem(value: year.id, child: Text(year.yearName))), //
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedYearId = value;
                          selectedClassId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Bộ lọc Lớp
                    DropdownButtonFormField<int>(
                      value: selectedClassId,
                      decoration: InputDecoration(
                        labelText: 'Lọc theo lớp',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tất cả lớp')), //
                        ...filteredClasses.map((klass) => DropdownMenuItem(value: klass.id, child: Text(klass.className))), //
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedClassId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Xử lý khi danh sách trống
                    if (filteredStudents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Không tìm thấy sinh viên phù hợp.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ),
                      
                    // Danh sách sinh viên (Áp dụng BoxConstraints + shrinkWrap chuẩn)
                    if (filteredStudents.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 280), // Chiều cao tối đa, ít phần tử sẽ tự co lại sát nút bộ lọc
                        child: ListView.builder(
                          shrinkWrap: true, // Ép ListView không chiếm diện tích thừa
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index]; //
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)), //
                                subtitle: Text('${student.username} • ${student.className}'), //
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () async {
                                    await _addParticipantToExam(student.id); //
                                    if (context.mounted) Navigator.pop(context); //
                                  },
                                  child: const Text('THÊM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    
                    // Nút Đóng cửa sổ ở dưới cùng
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context), //
                        child: const Text('ĐÓNG CỬA SỔ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeQuestion(int questionId) async {
    try {
      await _examService.removeQuestion(RemoveExamQuestionRequest(examId: widget.examId, questionId: questionId));
      await _loadDetail();
    } catch (e) {
      ErrorSnackbar.showError(context, e);
    }
  }

  Future<void> _startExam() async {
    try {
      await _examService.startExam(widget.examId);
      await _loadDetail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đề thi đã chính thức bắt đầu!')));
    } catch (e) {
      ErrorSnackbar.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        centerTitle: true,
        title: const Text('Chi tiết đề thi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadDetail)],
      ),
      body: _buildBody(),
      // ✨ Cụm Floating Action Button Extended bề thế tuyệt đẹp
      floatingActionButton: _exam == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]),
                    child: FloatingActionButton.extended(
                      heroTag: 'addQuestion',
                      onPressed: _showAddQuestionDialog,
                      backgroundColor: const Color(0xFF2563EB),
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      label: const Text('THÊM CÂU HỎI', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5, fontSize: 12.5)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]),
                    child: FloatingActionButton.extended(
                      heroTag: 'addParticipant',
                      onPressed: _showAddParticipantDialog,
                      backgroundColor: Colors.teal,
                      icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
                      label: const Text('THÊM THÍ SINH', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5, fontSize: 12.5)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Có lỗi xảy ra: $_errorMessage'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadDetail, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (_exam == null) return const Center(child: Text('Không tìm thấy dữ liệu đề thi.'));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card thông tin tổng quan lớn và nút Bắt đầu bự
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_exam!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const Divider(height: 24),
                Text('Trạng thái: ${_exam!.status}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Người tạo: ${_exam!.createdBy}'),
                const SizedBox(height: 4),
                Text('Ngày tạo: ${_exam!.createdAt}'),
                const SizedBox(height: 4),
                Text('Trộn câu hỏi: ${_exam!.shuffleOption ? 'Đang bật' : 'Tắt'}'),
                if (_exam!.status.toUpperCase() == 'WAITING') ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: _startExam,
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                      label: const Text('KÍCH HOẠT BẮT ĐẦU ĐỀ THI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                    ),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Danh sách câu hỏi trong đề', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          if (_questions.isEmpty) const Text('Chưa có câu hỏi nào trong đề thi.'),
          ..._questions.map((question) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Câu hỏi #${question.questionId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(question.questionContent, style: const TextStyle(color: Color(0xFF475569))),
                        const SizedBox(height: 4),
                        Text('Thứ tự: ${question.orderIndex}  |  Điểm số: ${question.questionScore}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  // ✨ Nút hành động xóa tăng diện tích nhạy bén
                  GestureDetector(
                    onTap: () async {
                      await _removeQuestion(question.questionId);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gỡ câu hỏi thành công!')));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                    ),
                  )
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text('Danh sách thí sinh tham dự', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          if (_participants.isEmpty) const Text('Chưa có thí sinh tham gia đề thi.'),
          ..._participants.map((participant) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(participant.userFullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('ID: ${participant.userId}  •  Trạng thái: ${participant.status}', style: const TextStyle(color: Color(0xFF475569))),
                        const SizedBox(height: 2),
                        Text('Điểm bài làm: ${participant.score ?? "Chưa có"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    ),
                  ),
                  // ✨ Nút hành động xóa thí sinh tăng diện tích nhạy bén
                  GestureDetector(
                    onTap: () async {
                      await _examService.removeParticipant(widget.examId, participant.userId);
                      await _loadDetail();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gỡ thí sinh khỏi đề thi!')));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.person_remove_alt_1_rounded, color: Colors.red, size: 22),
                    ),
                  )
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}