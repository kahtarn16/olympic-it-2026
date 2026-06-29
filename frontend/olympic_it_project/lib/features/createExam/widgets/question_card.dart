import 'package:flutter/material.dart';
import '../entities/question.dart';
import '../entities/answer.dart';
import '../entities/question_type.dart';
import '../entities/difficulty.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class QuestionCard extends StatefulWidget {
  final Question question;
  final VoidCallback onDelete;
  final bool showAddButton; // Thêm thuộc tính từ Step 2
  final VoidCallback onAddNext; // Thêm thuộc tính từ Step 2

  const QuestionCard({
    super.key,
    required this.question,
    required this.onDelete,
    required this.showAddButton,
    required this.onAddNext,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  late TextEditingController questionController;
  final ImagePicker picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (file == null) return;

    setState(() {
      widget.question.imageFile = File(file.path);
    });
  }

  Future<void> _pickVideo() async {
    final XFile? file = await picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (file == null) return;

    setState(() {
      widget.question.videoFile = File(file.path);
    });
  }

  @override
  void initState() {
    super.initState();
    questionController = TextEditingController(text: widget.question.content);
  }

  @override
void dispose() {
  questionController.dispose();

  for (final answer in widget.question.answers) {
    answer.dispose();
  }

  super.dispose();
}

  String _questionTypeText(QuestionType type) {
    switch (type) {
      case QuestionType.singleChoice:
        return "Trắc nghiệm 1 đáp án";
      case QuestionType.multipleChoice:
        return "Trắc nghiệm nhiều đáp án";
      case QuestionType.essay:
        return "Tự luận";
    }
  }

  String _difficultyText(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return "Dễ";
      case Difficulty.medium:
        return "Trung bình";
      case Difficulty.hard:
        return "Khó";
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEssay = widget.question.type == QuestionType.essay;

    return Column(
      children: [
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header câu hỏi
                Row(
                  children: [
                    Text(
                      "Câu ${widget.question.order}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onDelete,
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 15),

                /// Loại câu hỏi
                DropdownButtonFormField<QuestionType>(
                  value: widget.question.type,
                  decoration: const InputDecoration(
                    labelText: "Loại câu hỏi",
                    border: OutlineInputBorder(),
                  ),
                  items: QuestionType.values.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(_questionTypeText(e)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      widget.question.type = value;
                      // Nếu chuyển sang tự luận thì xóa danh sách đáp án đúng để tránh logic sai
                      if (value == QuestionType.essay) {
                        widget.question.correctAnswerIds.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 15),

                /// Nội dung câu hỏi
                TextField(
                  controller: questionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Nội dung câu hỏi",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    widget.question.content = value;
                  },
                ),
                const SizedBox(height: 15),

                /// Độ khó
                DropdownButtonFormField<Difficulty>(
                  value: widget.question.difficulty,
                  decoration: const InputDecoration(
                    labelText: "Độ khó",
                    border: OutlineInputBorder(),
                  ),
                  items: Difficulty.values.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(_difficultyText(e)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      widget.question.difficulty = value;
                    });
                  },
                ),
                const SizedBox(height: 20),

                /// Media đính kèm (Ảnh / Video)
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text("Ảnh"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam),
                      label: const Text("Video"),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                if (widget.question.imageFile != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      widget.question.imageFile!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          widget.question.imageFile = null;
                        });
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text("Xóa ảnh"),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],

                if (widget.question.videoFile != null) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.video_file),
                      title: Text(
                        widget.question.videoFile!.path.split('/').last,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          widget.question.videoFile = null;
                        });
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text("Xóa video"),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],

                const Divider(),
                const SizedBox(height: 10),

                /// Danh sách đáp án (Chỉ hiển thị nếu KHÔNG PHẢI tự luận)
                if (!isEssay) ...[
                  const Text(
                    "Danh sách đáp án (Tích chọn để làm đáp án đúng)",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ...widget.question.answers.map((answer) => _buildAnswer(answer)),
                  const SizedBox(height: 10),
                  
                  /// Nút thêm đáp án trắc nghiệm
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          widget.question.answers.add(
                            Answer(
                              id: String.fromCharCode(
                                65 + widget.question.answers.length,
                              ),
                              content: "",
                            ),
                          );
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Thêm đáp án"),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        /// Hiển thị nút "Thêm câu hỏi tiếp theo" dưới Card (Dựa theo logic Step 2)
        if (widget.showAddButton) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: widget.onAddNext,
            icon: const Icon(Icons.add_circle_outline, color: Color(0xff3b82f6)),
            label: const Text(
              "Thêm câu hỏi tiếp theo",
              style: TextStyle(
                color: Color(0xff3b82f6),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnswer(Answer answer) {
    // Tối ưu hóa việc tạo controller để tránh mất focus khi gõ text công thức/đáp án
    bool multiple =
    widget.question.type == QuestionType.multipleChoice;

    bool checked =
    widget.question.correctAnswerIds.contains(answer.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: checked ? const Color(0xff3b82f6) : Colors.grey[300],
            child: Text(
              answer.id,
              style: TextStyle(
                color: checked ? Colors.white : Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: answer.controller,
              decoration: InputDecoration(
                hintText: "Đáp án ${answer.id}",
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                answer.content = value;
              },
            ),
          ),
          const SizedBox(width: 10),
          
          // Nút xóa nhanh từng phương án lựa chọn (Nếu có > 1 đáp án)
          if (widget.question.answers.length > 1)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
              onPressed: () {
                setState(() {
                  widget.question.answers.remove(answer);
                  widget.question.correctAnswerIds.remove(answer.id);
                  // Cập nhật lại nhãn A, B, C, D từ đầu cho chuẩn
                  for (int i = 0; i < widget.question.answers.length; i++) {
                    widget.question.answers[i].id = String.fromCharCode(65 + i);
                  }
                });
              },
            ),

          multiple
              ? Checkbox(
                  value: checked,
                  onChanged: (val) {
                    setState(() {
                      if (checked) {
                        widget.question.correctAnswerIds.remove(answer.id);
                      } else {
                        widget.question.correctAnswerIds.add(answer.id);
                      }
                    });
                  },
                )
              : Radio<String>(
                  value: answer.id,
                  groupValue: widget.question.correctAnswerIds.isEmpty
                      ? null
                      : widget.question.correctAnswerIds.first,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      widget.question.correctAnswerIds.clear();
                      widget.question.correctAnswerIds.add(value);
                    });
                  },
                ),
        ],
      ),
    );
  }
}