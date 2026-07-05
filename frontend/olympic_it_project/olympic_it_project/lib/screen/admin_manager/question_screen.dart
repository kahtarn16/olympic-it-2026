import 'package:flutter/material.dart';
import 'package:olympic_it_project/dto/admin_manager/category/category_response.dart';
import 'package:olympic_it_project/dto/admin_manager/question/question_response.dart';
import 'package:olympic_it_project/screen/admin_manager/create_or_update_question_screen.dart';
import 'package:olympic_it_project/service/category_service.dart';
import 'package:olympic_it_project/service/question_service.dart';
import 'package:olympic_it_project/utils/error_snackbar.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({Key? key}) : super(key: key);

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final QuestionService _questionService = QuestionService();
  final CategoryService _categoryService = CategoryService();

  List<QuestionResponse> _questions = [];
  List<CategoryResponse> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;
  final int _pageSize = 10;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _onCategoryChanged(int? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _currentPage = 0;
    });
    await _fetchQuestions();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await _categoryService.getAll();
      if (!mounted) return;
      setState(() {
        _categories = categories;
      });
      await _fetchQuestions();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchQuestions({int? page}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final pageToLoad = page ?? _currentPage;
      final response = await _questionService.getAll(
        page: pageToLoad,
        size: _pageSize,
        categoryId: _selectedCategoryId,
      );
      setState(() {
        _questions = response.items;
        _currentPage = response.page;
        _totalPages = response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteQuestion(int id) async {
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
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
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade700]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 24),
                    const Text("Xóa câu hỏi này?", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    const Text(
                      "Hành động này không thể hoàn tác. Bạn chắc chắn muốn gỡ bỏ câu hỏi này khỏi hệ thống?",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("HỦY BỎ", style: TextStyle(color: Color(0xFF475569), fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(colors: [Colors.red.shade500, Colors.red.shade700]),
                              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("XÓA", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
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

    if (confirm == true) {
      try {
        await _questionService.delete(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Xóa thành công!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
        _fetchQuestions();
      } catch (e) {
        if (mounted) ErrorSnackbar.showError(context, e);
      }
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
        title: const Text('Quản lý Câu hỏi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 26),
            onPressed: _fetchQuestions,
          ),
        ],
      ),
      floatingActionButton: Container(
        height: 56, // Tăng chiều cao phím bấm chính
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateOrUpdateQuestionScreen()),
            );
            if (result == true) _fetchQuestions();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          label: const Text('THÊM CÂU HỎI MỚI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Lọc theo danh mục câu hỏi',
                labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18), // Tăng độ cao lọt lòng ô chọn
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả danh mục')),
                ..._categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
              ],
              onChanged: _onCategoryChanged,
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6), strokeWidth: 3.5));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 56),
              const SizedBox(height: 18),
              Text(
                'Có lỗi xảy ra:\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _fetchQuestions,
                child: const Text('Thử lại', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      );
    }
    if (_questions.isEmpty) {
      return const Center(child: Text('Chưa có câu hỏi nào.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 16)));
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchQuestions,
            color: const Color(0xFF3B82F6),
            strokeWidth: 3,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              physics: const BouncingScrollPhysics(),
              itemCount: _questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 18), // Giãn cách khoảng cách giữa các Card bự hơn
              itemBuilder: (context, index) {
                final q = _questions[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24), // Bo tròn mềm mại dáng hiện đại
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20), // Tăng khoảng trống đệm lọt lòng trong card câu hỏi
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hộp vuông hiển thị điểm số phóng to bự, rõ nét sắc sảo
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.09),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                q.score.toString(),
                                style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                q.content,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.5, letterSpacing: -0.1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        
                        // Khối nhãn Badge được đệm lọt lòng bự hẳn lên trông cực kì đẹp mắt
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                              child: Text('Loại: ${q.type.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                              child: Text('Độ khó: ${q.level.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2)),
                              child: Text('Danh mục: ${q.categoryName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            ),
                          ],
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1.5),
                        ),
                        
                        // Các nút tròn hành động to hơn hẳn, dễ click
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreateOrUpdateQuestionScreen(questionId: q.id),
                                  ),
                                );
                                if (result == true) _fetchQuestions();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14), // Phóng to diện tích nhận diện cảm ứng
                                decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.08), shape: BoxShape.circle),
                                child: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 24), // Biểu tượng bự rõ nét
                              ),
                            ),
                            const SizedBox(width: 14),
                            GestureDetector(
                              onTap: () => _deleteQuestion(q.id),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
                                child: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 24),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Hệ thống phân trang nút to rõ ràng, bo viền vững chãi
        if (_totalPages > 1)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: _currentPage > 0 ? const Color(0xFFCBD5E1) : Colors.grey.shade200, width: 1.5),
                  ),
                  onPressed: _currentPage > 0
                      ? () => _fetchQuestions(page: _currentPage - 1)
                      : null,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                  label: const Text('Trang trước', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Text(
                  'Trang ${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 15),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: _currentPage < _totalPages - 1 ? const Color(0xFFCBD5E1) : Colors.grey.shade200, width: 1.5),
                  ),
                  onPressed: _currentPage < _totalPages - 1
                      ? () => _fetchQuestions(page: _currentPage + 1)
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  label: const Text('Trang sau', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}