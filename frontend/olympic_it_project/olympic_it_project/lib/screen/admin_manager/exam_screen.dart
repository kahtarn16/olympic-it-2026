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
  final _examService = ExamService();

  bool loading = false;
  List<ExamResponse> exams = [];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => loading = true);

    try {
      final res = await _examService.getAllPaged(
        page: 0,
        size: 20,
        keyword: "",
      );

      setState(() {
        exams = res.data;
      });
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void _confirmDelete(int examId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Xóa đề thi"),
          content: const Text("Bạn có chắc muốn xóa đề thi này không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await _examService.delete(examId);

                  if (!mounted) return;

                  Navigator.pop(context);
                  await _loadExams();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Xóa thành công"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst("Exception: ", ""),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Xóa"),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(ExamResponse exam) {
    final nameController = TextEditingController(text: exam.name);
    bool shuffle = exam.shuffleOption;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Chỉnh sửa đề thi"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Tên đề thi"),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Text("Trộn câu hỏi"),
                      Switch(
                        value: shuffle,
                        onChanged: (value) {
                          setStateDialog(() {
                            shuffle = value;
                          });
                        },
                      ),
                    ],
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
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Vui lòng nhập tên đề thi"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      await _examService.update(
                        exam.id,
                        UpdateExamRequest(
                          name: nameController.text.trim(),
                          shuffleOption: shuffle,
                        ),
                      );

                      if (!mounted) return;

                      Navigator.pop(context);
                      await _loadExams();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Cập nhật thành công"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst("Exception: ", ""),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text("Lưu"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateExamDialog() {
    final nameController = TextEditingController();
    bool shuffle = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Thêm đề thi"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Tên đề thi"),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: shuffle,
                    title: const Text("Trộn câu hỏi"),
                    onChanged: (value) {
                      setStateDialog(() {
                        shuffle = value;
                      });
                    },
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
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Vui lòng nhập tên đề thi"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      final userId = await StorageToken.instance.getUserId();

                      if (userId == null) {
                        throw Exception("Không tìm thấy thông tin người dùng.");
                      }

                      await _examService.create(
                        CreateExamRequest(
                          name: nameController.text.trim(),
                          createdById: userId,
                          shuffleOption: shuffle,
                        ),
                      );

                      if (!mounted) return;

                      Navigator.pop(context);
                      await _loadExams();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Tạo đề thi thành công"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst("Exception: ", ""),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text("Tạo"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lí đề thi"),
        actions: [
          IconButton(
            onPressed: _showCreateExamDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExams,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: exams.length,
                itemBuilder: (context, index) {
                  final e = exams[index];

                  return Card(
                    child: ListTile(
                      title: Text(e.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Trạng thái: ${e.status}"),
                          Text("Được tạo bởi: ${e.createdBy}"),
                          const SizedBox(height: 4),

                          Row(
                            children: [
                              const Text("Trộn câu hỏi: "),
                              Text(
                                e.shuffleOption ? "BẬT" : "TẮT",
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExamDetailScreen(examId: e.id),
                          ),
                        );

                        _loadExams();
                      },

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: Colors.blue,
                            onPressed: e.status == "WAITING"
                                ? () => _showEditDialog(e)
                                : null,
                          ),

                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: e.status == "WAITING"
                                ? () => _confirmDelete(e.id)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
