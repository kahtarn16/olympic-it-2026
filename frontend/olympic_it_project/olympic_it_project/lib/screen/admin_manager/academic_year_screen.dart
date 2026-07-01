import 'package:flutter/material.dart';
import 'package:olympic_it_project/dto/admin_manager/academic_year/academic_year_response.dart';
import 'package:olympic_it_project/dto/admin_manager/academic_year/create_academic_year_request.dart';
import 'package:olympic_it_project/dto/admin_manager/academic_year/update_academic_year_request.dart';
import 'package:olympic_it_project/service/academic_service.dart';

class AcademicYearScreen extends StatefulWidget {
  const AcademicYearScreen({super.key});

  @override
  State<AcademicYearScreen> createState() => _AcademicYearScreenState();
}

class _AcademicYearScreenState extends State<AcademicYearScreen> {
  final _service = AcademicYearService();

  bool isLoading = true;
  List<AcademicYearResponse> academicYears = [];

  @override
  void initState() {
    super.initState();
    loadAcademicYears();
  }

  Future<void> loadAcademicYears() async {
    setState(() => isLoading = true);

    try {
      final data = await _service.getAll();

      setState(() {
        academicYears = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void showCreateDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thêm khóa học"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Tên khóa học",
            hintText: "VD: 2026-2028",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              await _service.create(
                CreateAcademicYearRequest(academicYearName: name),
              );

              Navigator.pop(context);
              loadAcademicYears();
            },
            child: const Text("Thêm"),
          ),
        ],
      ),
    );
  }

  void showEditDialog(AcademicYearResponse item) {
    final controller = TextEditingController(text: item.yearName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sửa khóa học"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Tên khóa học"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              await _service.update(
                item.id,
                UpdateAcademicYearRequest(academicYearName: name),
              );

              Navigator.pop(context);
              loadAcademicYears();
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
        title: const Text("Xóa khóa học"),
        content: const Text("Bạn chắc chắn muốn xóa?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.delete(id);
              Navigator.pop(context);
              loadAcademicYears();
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
          "Quản lý khóa học",
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
            const SizedBox(height: 10),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: academicYears.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = academicYears[index];

                        return Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                color: Colors.blue,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  item.yearName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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