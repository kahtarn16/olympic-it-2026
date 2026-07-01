import 'package:flutter/material.dart';
import 'package:olympic_it_project/dto/admin_manager/category/category_request.dart';
import 'package:olympic_it_project/dto/admin_manager/category/category_response.dart';
import 'package:olympic_it_project/service/category_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _service = CategoryService();

  bool isLoading = true;

  List<CategoryResponse> categories = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    try {
      final data = await _service.getAll();

      setState(() {
        categories = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("LOAD CATEGORY ERROR: $e");
    }
  }

  void showCreateDialog() {
    final name = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thêm loại câu hỏi"),
        content: TextField(
          controller: name,
          decoration: const InputDecoration(labelText: "Tên loại câu hỏi"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (name.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Vui lòng nhập tên thể loại"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              try {
                await _service.create(CategoryRequest(name: name.text));
                Navigator.pop(context);
                loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Thêm"),
          ),
        ],
      ),
    );
  }

  void showEditDialog(CategoryResponse item) {
    final name = TextEditingController(text: item.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sửa loại câu hỏi"),
        content: TextField(
          controller: name,
          decoration: const InputDecoration(labelText: "Tên loại câu hỏi"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (name.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Vui lòng nhập tên thể loại"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              try {
                await _service.update(item.id, CategoryRequest(name: name.text));
                Navigator.pop(context);
                loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
        title: const Text("Xóa loại câu hỏi"),
        content: const Text("Bạn chắc chắn muốn xóa loại câu hỏi này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _service.delete(id);
                Navigator.pop(context);
                loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
          "Quản lý loại câu hỏi",
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final c = categories[index];

                  return Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.category, color: Colors.indigo),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => showEditDialog(c),
                        ),

                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => confirmDelete(c.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
