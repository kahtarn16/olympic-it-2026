import 'package:flutter/material.dart';
import 'package:olympic_it_project/core/storage_token.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/create_exam_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/update_exam_request.dart';
import 'package:olympic_it_project/screen/admin_manager/exam_detail_screen.dart';
import 'package:olympic_it_project/service/exam_service.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final ExamService _examService = ExamService();
  final _nameController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<ExamResponse> _exams = [];

  final ScrollController _scrollController = ScrollController();

  int _page = 0;
  final int _size = 10;

  bool _hasMore = true;
  bool _isLoadingMore = false;
  int? _currentUserId;
  bool _createShuffle = false;

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _page + 1;

      final result = await _examService.getAllPaged(
        page: nextPage,
        size: _size,
      );

      setState(() {
        _page = nextPage;
        _exams.addAll(result.data);

        _hasMore = result.data.length == _size;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(() {
      if (!_isLoadingMore &&
          !_isLoading &&
          _hasMore &&
          _scrollController.position.extentAfter < 300) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _page = 0;
      _exams.clear();
      _hasMore = true;
      _isLoadingMore = false;
    });

    try {
      final userId = await StorageToken.instance.getUserId();

      final result = await _examService.getAllPaged(page: 0, size: _size);

      if (!mounted) return;

      setState(() {
        _currentUserId = userId;
        _exams = result.data;
        _hasMore = result.data.length == _size;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showExamDialog({ExamResponse? exam}) async {
    final isEdit = exam != null;
    final nameController = TextEditingController(text: exam?.name ?? '');
    bool shuffle = exam?.shuffleOption ?? false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'Chỉnh sửa đề thi' : 'Tạo đề thi mới'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Tên đề thi'),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: shuffle,
                    title: const Text('Trộn câu hỏi'),
                    onChanged: (value) {
                      setStateDialog(() {
                        shuffle = value ?? false;
                      });
                    },
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
                    if (nameController.text.trim().isEmpty) return;

                    if (isEdit) {
                      await _examService.update(
                        exam!.id,
                        UpdateExamRequest(
                          name: nameController.text.trim(),
                          shuffleOption: shuffle,
                        ),
                      );
                    } else {
                      await _examService.create(
                        CreateExamRequest(
                          name: nameController.text.trim(),
                          createdById: _currentUserId!,
                          shuffleOption: shuffle,
                        ),
                      );
                    }

                    if (context.mounted) Navigator.pop(context);
                    _loadData();
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(int examId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa đề thi'),
          content: const Text('Bạn chắc chắn muốn xóa đề thi này không?'),
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
        );
      },
    );

    if (confirm != true) return;

    try {
      await _examService.delete(examId);
      _loadData();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xóa đề thi thành công')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Đề thi'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExamDialog(),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _exams.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Có lỗi xảy ra:\n$_errorMessage',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Chưa có đề thi nào.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _showExamDialog(),
              child: const Text('Tạo đề thi mới'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: _exams.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _exams.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final exam = _exams[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    exam.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Trạng thái: ${exam.status}\n'
                    'Người tạo: ${exam.createdBy}\n'
                    'Ngày tạo: ${exam.createdAt}\n'
                    'Trộn câu hỏi: ${exam.shuffleOption ? 'Có' : 'Không'}',
                  ),
                  isThreeLine: true,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExamDetailScreen(examId: exam.id),
                      ),
                    );
                    _loadData();
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showExamDialog(exam: exam),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(exam.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // 🔥 overlay loading khi refresh (không che list hoàn toàn)
        if (_isLoading && _exams.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}
