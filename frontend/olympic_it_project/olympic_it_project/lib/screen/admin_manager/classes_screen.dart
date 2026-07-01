import 'package:flutter/material.dart';
import 'package:olympic_it_project/dto/admin_manager/classes/classes_response.dart';
import 'package:olympic_it_project/dto/admin_manager/classes/create_class_request.dart';
import 'package:olympic_it_project/dto/admin_manager/classes/update_class_request.dart';
import 'package:olympic_it_project/dto/admin_manager/academic_year/academic_year_response.dart';
import 'package:olympic_it_project/service/classes_service.dart';
import 'package:olympic_it_project/service/academic_service.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _classService = ClassService();
  final _yearService = AcademicYearService();

  bool isLoading = true;

  List<ClassResponse> classes = [];
  List<AcademicYearResponse> years = [];

  int? selectedYearId;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    setState(() => isLoading = true);

    try {
      final yearData = await _yearService.getAll();
      final classData = await _classService.getAll();

      setState(() {
        years = yearData;
        classes = classData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadClasses() async {
    try {
      final data = await _classService.getAll(academicYearId: selectedYearId);

      setState(() {
        classes = data;
      });
    } catch (e) {}
  }

  void showCreateDialog() {
    final nameController = TextEditingController();
    int? yearId;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thêm lớp"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Tên lớp"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: yearId,
              decoration: const InputDecoration(labelText: "Khóa học"),
              items: years
                  .map(
                    (y) =>
                        DropdownMenuItem(value: y.id, child: Text(y.yearName)),
                  )
                  .toList(),
              onChanged: (value) => yearId = value,
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
              if (nameController.text.trim().isEmpty || yearId == null) return;

              await _classService.create(
                CreateClassRequest(
                  className: nameController.text.trim(),
                  academicYearId: yearId!,
                ),
              );

              Navigator.pop(context);
              loadClasses();
            },
            child: const Text("Thêm"),
          ),
        ],
      ),
    );
  }

  void showEditDialog(ClassResponse item) {
    final nameController = TextEditingController(text: item.className);
    int? yearId = item.academicYearId;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sửa lớp"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Tên lớp"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: yearId,
              decoration: const InputDecoration(labelText: "Khóa học"),
              items: years
                  .map(
                    (y) =>
                        DropdownMenuItem(value: y.id, child: Text(y.yearName)),
                  )
                  .toList(),
              onChanged: (value) => yearId = value,
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
              if (yearId == null) return;

              await _classService.update(
                item.id,
                UpdateClassRequest(
                  className: nameController.text.trim(),
                  academicYearId: yearId!,
                ),
              );

              Navigator.pop(context);
              loadClasses();
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
        title: const Text("Xóa lớp"),
        content: const Text("Bạn chắc chắn muốn xóa?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _classService.delete(id);
              Navigator.pop(context);
              loadClasses();
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B82F6),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3B82F6),
        centerTitle: true,
        title: const Text(
          "Quản lý lớp học",
          style: TextStyle(color: Colors.white),
        ),
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
            // ================= FILTER =================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<int>(
                value: selectedYearId,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text("Lọc theo khóa học"),
                items: years
                    .map(
                      (y) => DropdownMenuItem(
                        value: y.id,
                        child: Text(y.yearName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedYearId = value;
                  });
                  loadClasses();
                },
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: classes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = classes[index];

                        final yearName = years
                            .firstWhere(
                              (y) => y.id == item.academicYearId,
                              orElse: () => AcademicYearResponse(
                                id: 0,
                                yearName: "Unknown",
                              ),
                            )
                            .yearName;

                        return Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.class_, color: Colors.blue),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.className,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      yearName,
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
                                onPressed: () => showEditDialog(item),
                              ),

                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => confirmDelete(item.id),
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
