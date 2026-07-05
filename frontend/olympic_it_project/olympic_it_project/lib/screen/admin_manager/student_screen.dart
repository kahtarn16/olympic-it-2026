import 'package:flutter/material.dart';
import 'package:olympic_it_project/dto/admin_manager/student/create_student_request.dart';
import 'package:olympic_it_project/dto/admin_manager/classes/classes_response.dart';
import 'package:olympic_it_project/dto/admin_manager/student/student_response.dart';
import 'package:olympic_it_project/dto/admin_manager/student/update_student_request.dart';
import 'package:olympic_it_project/service/student_service.dart';
import 'package:olympic_it_project/service/classes_service.dart';
import 'package:olympic_it_project/utils/error_snackbar.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final _studentService = StudentService();
  final _classService = ClassService();

  bool isLoading = true;

  List<StudentResponse> students = [];
  List<ClassResponse> classes = [];

  int? selectedClassId;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    setState(() => isLoading = true);
    try {
      final s = await _studentService.getAll();
      final c = await _classService.getAll();

      setState(() {
        students = s;
        classes = c;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) ErrorSnackbar.showError(context, e);
    }
  }

  Future<void> loadStudents() async {
    setState(() => isLoading = true);
    try {
      final data = await _studentService.getAll();
      setState(() {
        students = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) ErrorSnackbar.showError(context, e);
    }
  }

  // ✨ WOW Form: Thêm sinh viên mới căn giữa màn hình
  void showCreateDialog() {
    final username = TextEditingController();
    final password = TextEditingController();
    final email = TextEditingController();
    final fullName = TextEditingController();
    int? classId = classes.isNotEmpty ? classes.first.id : null;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFF59E0B), size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Thêm sinh viên mới",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          DropdownButtonFormField<int>(
                            value: classId,
                            isExpanded: true,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              labelText: "Chọn lớp học",
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                            items: classes.map((c) {
                              return DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(c.className),
                              );
                            }).toList(),
                            onChanged: (val) => setDialogState(() => classId = val),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              labelText: "Họ và tên",
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: email,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              labelText: "Địa chỉ Email",
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: username,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              labelText: "Username (Mã SV)",
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: password,
                            obscureText: true,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              labelText: "Mật khẩu",
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Hủy", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  if (username.text.isEmpty ||
                                      password.text.isEmpty ||
                                      email.text.isEmpty ||
                                      fullName.text.isEmpty ||
                                      classId == null) return;

                                  try {
                                    await _studentService.create(
                                      CreateStudentRequest(
                                        username: username.text,
                                        password: password.text,
                                        email: email.text,
                                        fullName: fullName.text,
                                        classId: classId!,
                                      ),
                                    );
                                    if (context.mounted) Navigator.pop(context);
                                    loadStudents();
                                  } catch (e) {
                                    if (context.mounted) ErrorSnackbar.showError(context, e);
                                  }
                                },
                                child: const Text("Thêm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  // ✨ WOW Form: Cập nhật thông tin sinh viên căn giữa màn hình (Không mật khẩu)
  void showEditDialog(StudentResponse item) {
    final username = TextEditingController(text: item.username);
    final email = TextEditingController(text: item.email);
    final fullName = TextEditingController(text: item.fullName);
    int? classId = item.classId;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.mode_edit_outline_rounded, color: Color(0xFF3B82F6), size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Sửa thông tin sinh viên",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          DropdownButtonFormField<int>(
                            value: classId,
                            isExpanded: true,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              labelText: "Lớp học",
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                            items: classes.map((c) {
                              return DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(c.className),
                              );
                            }).toList(),
                            onChanged: (val) => setDialogState(() => classId = val),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              labelText: "Họ và tên",
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: email,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              labelText: "Địa chỉ Email",
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: username,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              labelText: "Username",
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Hủy", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  if (classId == null) return;

                                  try {
                                    await _studentService.update(
                                      item.id,
                                      UpdateStudentRequest(
                                        username: username.text,
                                        email: email.text,
                                        fullName: fullName.text,
                                        classId: classId!,
                                      ),
                                    );
                                    if (context.mounted) Navigator.pop(context);
                                    loadStudents();
                                  } catch (e) {
                                    if (context.mounted) ErrorSnackbar.showError(context, e);
                                  }
                                },
                                child: const Text("Lưu", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  // ✨ WOW Form: Hộp thoại xác nhận khóa sinh viên căn giữa
  void confirmDelete(int id) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.lock_person_rounded, color: Colors.red.shade600, size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text("Khóa sinh viên này?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    const Text(
                      "Bạn chắc chắn muốn khóa sinh viên này khỏi hệ thống?",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Hủy", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              try {
                                await _studentService.delete(id);
                                if (context.mounted) Navigator.pop(context);
                                loadStudents();
                              } catch (e) {
                                if (context.mounted) ErrorSnackbar.showError(context, e);
                              }
                            },
                            child: const Text("Khóa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void filterByClass(int? id) {
    setState(() {
      selectedClassId = id;
    });
  }

  List<StudentResponse> get filteredStudents {
    if (selectedClassId == null) return students;
    return students.where((e) => e.classId == selectedClassId).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Tìm tên lớp học hiện tại đang được chọn lọc để hiển thị lên thanh tiêu đề bộ lọc
    String selectedClassName = "Tất cả lớp học";
    if (selectedClassId != null) {
      final currentClass = classes.firstWhere((c) => c.id == selectedClassId, 
          orElse: () => ClassResponse(id: 0, className: "Không rõ", academicYearId: 0));
      selectedClassName = currentClass.className;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        centerTitle: true,
        title: const Text("Quản lý sinh viên", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      floatingActionButton: Container(
        height: 64, width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: FloatingActionButton(
          onPressed: showCreateDialog,
          backgroundColor: const Color(0xFF3B82F6),
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 28),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 14),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.03), 
                    blurRadius: 10, 
                    offset: const Offset(0, 4)
                  )
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<int?>(
                  value: selectedClassId,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(14),
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 22),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.filter_list_rounded, color: Color(0xFF3B82F6), size: 20),
                    prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 0),
                    labelText: "Lọc theo lớp học",
                    labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 14),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF1E293B)
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text("Tất cả lớp học", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                    ),
                    ...classes.map((c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text("🏫 ${c.className}"),
                        )),
                  ],
                  onChanged: filterByClass,
                ),
              ),
            ),
                        
            const SizedBox(height: 14),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                  : ListView.separated(
                      itemCount: filteredStudents.length,
                      physics: const BouncingScrollPhysics(),
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final s = filteredStudents[index];

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 8))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.fullName,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "${s.username}  •  ${s.className}",
                                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => showEditDialog(s),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.08), shape: BoxShape.circle),
                                  child: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 18),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => confirmDelete(s.id),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
                                  child: const Icon(Icons.lock_outline_rounded, color: Colors.red, size: 18),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}