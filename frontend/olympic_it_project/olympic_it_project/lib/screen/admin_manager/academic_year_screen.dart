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

  // ✨ WOW: Form tạo khóa học căn chính giữa màn hình siêu chuyên nghiệp
  void showCreateDialog() {
    final controller = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.4), // Làm mờ nền phía sau tinh tế
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Hiệu ứng scale nhẹ từ tâm cực mượt
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24), // Bo góc sâu luxury
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
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
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_box_rounded, color: Color(0xFF3B82F6), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Thêm khóa học",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        labelText: "Tên khóa học",
                        hintText: "VD: 2026-2028",
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
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
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
                            final name = controller.text.trim();
                            if (name.isEmpty) return;

                            await _service.create(
                              CreateAcademicYearRequest(academicYearName: name),
                            );

                            Navigator.pop(context);
                            loadAcademicYears();
                          },
                          child: const Text("Thêm mới", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✨ WOW: Form sửa khóa học căn chính giữa màn hình đồng bộ thiết kế cao cấp
  void showEditDialog(AcademicYearResponse item) {
    final controller = TextEditingController(text: item.yearName);

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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
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
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.mode_edit_outline_rounded, color: Color(0xFF3B82F6), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Sửa khóa học",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        labelText: "Tên khóa học",
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
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
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
                            final name = controller.text.trim();
                            if (name.isEmpty) return;

                            await _service.update(
                              item.id,
                              UpdateAcademicYearRequest(academicYearName: name),
                            );

                            Navigator.pop(context);
                            loadAcademicYears();
                          },
                          child: const Text("Cập nhật", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✨ WOW: Hộp thoại xác nhận xóa dạng popup ở trung tâm đồng bộ đồng điệu mượt mà
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade600, size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text("Xóa khóa học này?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    const Text(
                      "Hành động này không thể hoàn tác. Bạn có chắc chắn muốn xóa khóa học này không?",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
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
                              await _service.delete(id);
                              Navigator.pop(context);
                              loadAcademicYears();
                            },
                            child: const Text("Xóa bỏ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFFF1F5F9), // Nền xám nhạt cao cấp giúp nổi bật Card trắng

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white, // AppBar trắng sang trọng theo xu hướng hiện đại
        foregroundColor: const Color(0xFF1E293B),
        centerTitle: true,
        title: const Text(
          "Quản lý khóa học",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),

      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
          ],
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
                      itemCount: academicYears.length,
                      physics: const BouncingScrollPhysics(), // Cuộn nẩy iOS mượt mà
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = academicYears[index];

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20), // Thẻ bo góc sâu tinh tế theo ảnh mẫu
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.03),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Khối Icon chứa hiệu ứng Gradient chuyển màu thời thượng
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                              ),

                              const SizedBox(width: 16),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Năm học / Khóa",
                                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.yearName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Nút Sửa mờ tinh tế dạng tròn hành động
                              GestureDetector(
                                onTap: () => showEditDialog(item),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.08), shape: BoxShape.circle),
                                  child: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 18),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Nút Xóa mờ dịu mắt tránh cảm giác nặng nề
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