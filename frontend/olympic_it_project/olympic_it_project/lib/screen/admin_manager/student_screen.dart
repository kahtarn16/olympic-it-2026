import 'package:flutter/material.dart';
import 'package:olympic_it_project/dto/admin_manager/student/create_student_request.dart';

import 'package:olympic_it_project/dto/admin_manager/classes/classes_response.dart';
import 'package:olympic_it_project/dto/admin_manager/student/student_response.dart';
import 'package:olympic_it_project/dto/admin_manager/student/update_student_request.dart';

import 'package:olympic_it_project/service/student_service.dart';
import 'package:olympic_it_project/service/classes_service.dart';

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

    debugPrint("INIT ERROR: $e");
  }
}

  Future<void> loadStudents() async {
    setState(() => isLoading = true);

    final data = await _studentService.getAll();

    setState(() {
      students = data;
      isLoading = false;
    });
  }

  void showCreateDialog() {
    final username = TextEditingController();
    final password = TextEditingController();
    final email = TextEditingController();
    final fullName = TextEditingController();
    int? classId;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thêm sinh viên"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: username,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: password,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: fullName,
              decoration: const InputDecoration(labelText: "Họ tên"),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<int>(
              value: classId,
              decoration: const InputDecoration(labelText: "Lớp"),
              items: classes
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.className),
                      ))
                  .toList(),
              onChanged: (v) => classId = v,
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
              if (username.text.isEmpty ||
                  password.text.isEmpty ||
                  email.text.isEmpty ||
                  fullName.text.isEmpty ||
                  classId == null) return;

              await _studentService.create(
                CreateStudentRequest(
                  username: username.text,
                  password: password.text,
                  email: email.text,
                  fullName: fullName.text,
                  classId: classId!,
                ),
              );

              Navigator.pop(context);
              loadStudents();
            },
            child: const Text("Thêm"),
          ),
        ],
      ),
    );
  }

  void showEditDialog(StudentResponse item) {
    final username = TextEditingController(text: item.username);
    final email = TextEditingController(text: item.email);
    final fullName = TextEditingController(text: item.fullName);

    int? classId = item.classId;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sửa sinh viên"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: username,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: fullName,
              decoration: const InputDecoration(labelText: "Họ tên"),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<int>(
              value: classId,
              decoration: const InputDecoration(labelText: "Lớp"),
              items: classes
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.className),
                      ))
                  .toList(),
              onChanged: (v) => classId = v,
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
              if (classId == null) return;

              await _studentService.update(
                item.id,
                UpdateStudentRequest(
                  username: username.text,
                  email: email.text,
                  fullName: fullName.text,
                  classId: classId!,
                ),
              );

              Navigator.pop(context);
              loadStudents();
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Khóa sinh viên"),
        content: const Text("Bạn chắc chắn muốn khóa sinh viên này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _studentService.delete(id);
              Navigator.pop(context);
              loadStudents();
            },
            child: const Text("Khóa"),
          ),
        ],
      ),
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
    return Scaffold(
      backgroundColor: const Color(0xFF3B82F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFF3B82F6),
        title: const Text("Quản lý sinh viên"),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: showCreateDialog,
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Color(0xFF3B82F6)),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<int>(
                value: selectedClassId,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text("Lọc theo lớp"),
                items: classes
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.className),
                        ))
                    .toList(),
                onChanged: filterByClass,
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: filteredStudents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final s = filteredStudents[index];

                        return Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: Colors.blue),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${s.username} • ${s.className}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => showEditDialog(s),
                              ),

                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => confirmDelete(s.id),
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