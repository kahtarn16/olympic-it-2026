import 'package:flutter/material.dart';
import 'package:olympic_it_project/dto/admin_manager/classes/classes_response.dart';
import 'package:olympic_it_project/dto/admin_manager/classes/create_class_request.dart';
import 'package:olympic_it_project/dto/admin_manager/classes/update_class_request.dart';
import 'package:olympic_it_project/dto/admin_manager/academic_year/academic_year_response.dart';
import 'package:olympic_it_project/service/classes_service.dart';
import 'package:olympic_it_project/service/academic_service.dart';
import 'package:olympic_it_project/utils/error_snackbar.dart';

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
      final yearsData = await _yearService.getAll();
      final classesData = await _classService.getAll();

      setState(() {
        years = yearsData;
        classes = classesData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) ErrorSnackbar.showError(context, e);
    }
  }

  // ✨ WOW Form: Tạo lớp học căn giữa màn hình với Dropdown khóa học
  void showCreateDialog() {
    final nameController = TextEditingController();
    int? localSelectedYearId = years.isNotEmpty ? years.first.id : null;

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
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.school_rounded, color: Color(0xFF10B981), size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Tạo lớp học mới",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        DropdownButtonFormField<int>(
                          value: localSelectedYearId,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            labelText: "Thuộc khóa / Năm học",
                            labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                          items: years.map((y) {
                            return DropdownMenuItem<int>(
                              value: y.id,
                              child: Text(y.yearName),
                            );
                          }).toList(),
                          onChanged: (val) => setDialogState(() => localSelectedYearId = val),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: nameController,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            labelText: "Tên lớp học",
                            hintText: "VD: Công nghệ thông tin 1",
                            labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                            ),
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
                                final name = nameController.text.trim();
                                if (name.isEmpty || localSelectedYearId == null) return;

                                try {
                                  await _classService.create(
                                    CreateClassRequest(className: name, academicYearId: localSelectedYearId!),
                                  );
                                  if (context.mounted) Navigator.pop(context);
                                  initData();
                                } catch (e) {
                                  if (context.mounted) ErrorSnackbar.showError(context, e);
                                }
                              },
                              child: const Text("Tạo lớp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
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

  // ✨ WOW Form: Sửa lớp học căn giữa màn hình
  void showEditDialog(ClassResponse item) {
    final nameController = TextEditingController(text: item.className);
    int? localSelectedYearId = item.academicYearId;

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
                              "Cập nhật lớp học",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        DropdownButtonFormField<int>(
                          value: localSelectedYearId,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            labelText: "Thuộc khóa / Năm học",
                            labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                          items: years.map((y) {
                            return DropdownMenuItem<int>(
                              value: y.id,
                              child: Text(y.yearName),
                            );
                          }).toList(),
                          onChanged: (val) => setDialogState(() => localSelectedYearId = val),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: nameController,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            labelText: "Tên lớp học",
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                            ),
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
                                final name = nameController.text.trim();
                                if (name.isEmpty || localSelectedYearId == null) return;

                                try {
                                  await _classService.update(
                                    item.id,
                                    UpdateClassRequest(className: name, academicYearId: localSelectedYearId!),
                                  );
                                  if (context.mounted) Navigator.pop(context);
                                  initData();
                                } catch (e) {
                                  if (context.mounted) ErrorSnackbar.showError(context, e);
                                }
                              },
                              child: const Text("Lưu thay đổi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
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

  // ✨ WOW Form: Xác nhận xóa lớp học căn giữa màn hình
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
                      child: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade600, size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text("Xóa lớp học này?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    const Text(
                      "Tất cả sinh viên thuộc lớp này sẽ mất liên kết dữ liệu lớp học. Bạn chắc chắn muốn xóa?",
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
                                await _classService.delete(id);
                                if (context.mounted) Navigator.pop(context);
                                initData();
                              } catch (e) {
                                if (context.mounted) ErrorSnackbar.showError(context, e);
                              }
                            },
                            child: const Text("Xóa ngay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        centerTitle: true,
        title: const Text("Quản lý lớp học", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                  : ListView.separated(
                      itemCount: classes.length,
                      physics: const BouncingScrollPhysics(),
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = classes[index];
                        
                        // 🟢 FIX LỖI TẠI ĐÂY: Ánh xạ thủ công id sang tên năm học giống như code gốc của bạn
                        final year = years.firstWhere(
                          (y) => y.id == item.academicYearId,
                          orElse: () => AcademicYearResponse(id: 0, yearName: "Chưa rõ khóa"),
                        );
                        final yearName = year.yearName;

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
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.className,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Khóa: $yearName",
                                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => showEditDialog(item),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.08), shape: BoxShape.circle),
                                  child: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 18),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => confirmDelete(item.id),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
                                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
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