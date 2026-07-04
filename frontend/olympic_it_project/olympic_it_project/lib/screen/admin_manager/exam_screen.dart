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
  int? _currentUserId;
  bool _createShuffle = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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
    });

    try {
      final userId = await StorageToken.instance.getUserId();
      final exams = await _examService.getAll();
      if (!mounted) return;
      setState(() {
        _currentUserId = userId;
        _exams = exams;
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

  Future<void> _showExamDialog({ExamResponse? exam}) async {
    final isEdit = exam != null;
    _nameController.text = exam?.name ?? '';
    _createShuffle = exam?.shuffleOption ?? false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Chỉnh sửa đề thi' : 'Tạo đề thi mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên đề thi'),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _createShuffle,
                title: const Text('Trộn câu hỏi'),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _createShuffle = value;
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
                if (_nameController.text.trim().isEmpty) return;
                try {
                  if (isEdit) {
                    await _examService.update(
                      exam!.id,
                      UpdateExamRequest(
                        name: _nameController.text.trim(),
                        shuffleOption: _createShuffle,
                      ),
                    );
                  } else {
                    if (_currentUserId == null) {
                      throw Exception('Không xác định được tài khoản hiện tại');
                    }
                    await _examService.create(
                      CreateExamRequest(
                        name: _nameController.text.trim(),
                        createdById: _currentUserId!,
                        shuffleOption: _createShuffle,
                      ),
                    );
                  }
                  Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa đề thi thành công')), 
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Đề thi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Có lỗi xảy ra:\n$_errorMessage', textAlign: TextAlign.center),
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _exams.length,
        itemBuilder: (context, index) {
          final exam = _exams[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(exam.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Trạng thái: ${exam.status}\nNgười tạo: ${exam.createdBy}\nNgày tạo: ${exam.createdAt}\nTrộn câu hỏi: ${exam.shuffleOption ? 'Có' : 'Không'}',
              ),
              isThreeLine: true,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ExamDetailScreen(examId: exam.id)),
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
    );
  }
}
