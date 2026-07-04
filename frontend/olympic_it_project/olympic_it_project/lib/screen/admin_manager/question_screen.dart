import 'package:flutter/material.dart';
import 'package:olympic_it_project/dto/admin_manager/category/category_response.dart';
import 'package:olympic_it_project/dto/admin_manager/question/question_response.dart';
import 'package:olympic_it_project/screen/admin_manager/create_or_update_question_screen.dart';
import 'package:olympic_it_project/service/category_service.dart';
import 'package:olympic_it_project/service/question_service.dart';

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
  int _pageSize = 10;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _onCategoryChanged(int categoryId) async {
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa câu hỏi này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _questionService.delete(id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xóa thành công!')));
        _fetchQuestions(); // Cập nhật lại danh sách
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Câu hỏi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchQuestions,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Chuyển sang màn hình Form, nếu thêm thành công thì load lại list
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateOrUpdateQuestionScreen(),
            ),
          );
          if (result == true) _fetchQuestions();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'Lọc theo danh mục:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                        _currentPage = 0;
                      });
                      _fetchQuestions();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Có lỗi xảy ra:\n$_errorMessage', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchQuestions,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (_questions.isEmpty) {
      return const Center(child: Text('Chưa có câu hỏi nào.'));
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchQuestions,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final q = _questions[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(q.score.toString()), // Hiển thị điểm số
                    ),
                    title: Text(
                      q.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Loại: ${q.type.name} | Độ khó: ${q.level.name}\nDanh mục: ${q.categoryName}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateOrUpdateQuestionScreen(
                                  questionId: q.id,
                                ),
                              ),
                            );
                            if (result == true) _fetchQuestions();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteQuestion(q.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 0
                      ? () => _fetchQuestions(page: _currentPage - 1)
                      : null,
                  child: const Text('Trang trước'),
                ),
                Text('Trang ${_currentPage + 1} / $_totalPages'),
                ElevatedButton(
                  onPressed: _currentPage < _totalPages - 1
                      ? () => _fetchQuestions(page: _currentPage + 1)
                      : null,
                  child: const Text('Trang sau'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
