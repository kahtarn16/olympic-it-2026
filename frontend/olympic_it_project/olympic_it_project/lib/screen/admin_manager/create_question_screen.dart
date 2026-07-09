import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:olympic_it_project/core/question_level.dart';
import 'package:olympic_it_project/core/question_type.dart';
import 'package:olympic_it_project/dto/admin_manager/question/create_question_request.dart';
import 'package:olympic_it_project/dto/admin_manager/question/create_question_option_request.dart';
import 'package:olympic_it_project/dto/admin_manager/question/question_response.dart';
import 'package:olympic_it_project/dto/admin_manager/question/update_question_request.dart';
import 'package:olympic_it_project/service/question_service.dart';
import 'package:olympic_it_project/service/upload_service.dart';


class CreateQuestionScreen extends StatefulWidget {
  final QuestionResponse? questionToEdit;

  const CreateQuestionScreen({Key? key, this.questionToEdit}) : super(key: key);

  @override
  State<CreateQuestionScreen> createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends State<CreateQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionService = QuestionService();
  final _uploadService = UploadService();

  final ImagePicker _picker = ImagePicker();

  late TextEditingController _contentCtrl;
  late TextEditingController _scoreCtrl;
  late TextEditingController _timeLimitCtrl;
  late TextEditingController _categoryIdCtrl;

  QuestionType _selectedType = QuestionType.MCQ_TEXT;
  QuestionLevel _selectedLevel = QuestionLevel.EASY;

  // --- Logic kiểm tra loại câu hỏi ---
  bool get isMediaQuestion =>
      _selectedType == QuestionType.MCQ_MEDIA ||
      _selectedType == QuestionType.ESSAY_MEDIA;

  bool get isEssayQuestion => _selectedType.name.contains("ESSAY");

  String? _questionImageUrl;
  String? _questionVideoUrl;

  final List<String> _labels = ['A', 'B', 'C', 'D'];
  late List<TextEditingController> _optionTextCtrls;
  late List<String?> _optionImageUrls;
  int _correctOptionIndex = 0;

  bool _isSubmitting = false;
  bool _isUploadingMedia = false;
  bool get isEditMode => widget.questionToEdit != null;

  @override
  void initState() {
    super.initState();
    final q = widget.questionToEdit;
    _contentCtrl = TextEditingController(text: q?.content ?? '');
    _scoreCtrl = TextEditingController(text: q?.score.toString() ?? '10');
    _timeLimitCtrl = TextEditingController(text: q?.timeLimit.toString() ?? '60');
    _categoryIdCtrl = TextEditingController(text: q?.categoryId.toString() ?? '1');

    _optionTextCtrls = List.generate(4, (_) => TextEditingController());
    _optionImageUrls = List.filled(4, null);

    if (q != null) {
      _selectedType = q.type;
      _selectedLevel = q.level;
      _questionImageUrl = q.imageUrl;
      _questionVideoUrl = q.videoUrl;
    }
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _scoreCtrl.dispose();
    _timeLimitCtrl.dispose();
    _categoryIdCtrl.dispose();
    for (var ctrl in _optionTextCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickMedia({bool isQuestion = true, bool isVideo = false, int? optionIndex}) async {
    try {
      final XFile? file = isVideo 
          ? await _picker.pickVideo(source: ImageSource.gallery)
          : await _picker.pickImage(source: ImageSource.gallery);

      if (file == null) return;

      setState(() => _isUploadingMedia = true);

      // TODO: [QUAN TRỌNG] Gọi API Upload của bạn ở đây!
      // Ví dụ: String uploadedUrl = await _uploadService.uploadFile(File(file.path));
      
      // TẠM THỜI gán đường dẫn file local để bạn test UI không bị crash
      String uploadedUrl = file.path; 
      await Future.delayed(const Duration(seconds: 1)); // Giả lập mạng chậm 1s

      setState(() {
        if (isQuestion) {
          if (isVideo) {
            _questionVideoUrl = uploadedUrl;
            _questionImageUrl = null; // Backend chỉ nhận 1 trong 2
          } else {
            _questionImageUrl = uploadedUrl;
            _questionVideoUrl = null;
          }
        } else if (optionIndex != null) {
          _optionImageUrls[optionIndex] = uploadedUrl;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tải file thành công!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải file: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploadingMedia = false);
    }
  }

  // --- HÀM SUBMIT & VALIDATE CHẶT CHẼ ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải file, vui lòng đợi!'), backgroundColor: Colors.orange),
      );
      return;
    }

    // 1. Validate Media cho Câu hỏi chính
    if (isMediaQuestion) {
      if ((_questionImageUrl == null || _questionImageUrl!.isEmpty) &&
          (_questionVideoUrl == null || _questionVideoUrl!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi: Câu hỏi Media bắt buộc phải có Hình ảnh hoặc Video!'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    // 2. Validate cho 4 Đáp án (Chỉ check nếu KHÔNG PHẢI là tự luận)
    if (!isEssayQuestion) {
      if (_selectedType == QuestionType.MCQ_TEXT) {
        for (int i = 0; i < 4; i++) {
          if (_optionTextCtrls[i].text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: Vui lòng nhập nội dung cho đáp án ${_labels[i]}!'), backgroundColor: Colors.red),
            );
            return;
          }
        }
      } else if (_selectedType == QuestionType.MCQ_MEDIA) {
        for (int i = 0; i < 4; i++) {
          if (_optionImageUrls[i] == null || _optionImageUrls[i]!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: Vui lòng tải ảnh lên cho đáp án ${_labels[i]}!'), backgroundColor: Colors.red),
            );
            return;
          }
        }
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // Đóng gói 4 đáp án (Nếu tự luận thì truyền rỗng)
      List<CreateQuestionOptionRequest> optionsReq = isEssayQuestion ? [] : List.generate(4, (index) {
        return CreateQuestionOptionRequest(
          label: _labels[index],
          contentText: _selectedType == QuestionType.MCQ_TEXT ? _optionTextCtrls[index].text.trim() : '',
          imageUrl: _selectedType == QuestionType.MCQ_MEDIA ? (_optionImageUrls[index] ?? '') : '',
          isCorrect: _correctOptionIndex == index,
        );
      });

      if (isEditMode) {
        final updateReq = UpdateQuestionRequest(
          content: _contentCtrl.text.trim(),
          type: _selectedType,
          level: _selectedLevel,
          categoryId: int.parse(_categoryIdCtrl.text.trim()),
          score: int.parse(_scoreCtrl.text.trim()),
          timeLimit: int.parse(_timeLimitCtrl.text.trim()),
          imageUrl: _questionImageUrl,
          videoUrl: _questionVideoUrl,
          options: optionsReq,
        );
        await _questionService.update(widget.questionToEdit!.id, updateReq);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công'), backgroundColor: Colors.green));
        }
      } else {
        final createReq = CreateQuestionRequest(
          content: _contentCtrl.text.trim(),
          type: _selectedType,
          level: _selectedLevel,
          categoryId: int.parse(_categoryIdCtrl.text.trim()),
          score: int.parse(_scoreCtrl.text.trim()),
          timeLimit: int.parse(_timeLimitCtrl.text.trim()),
          imageUrl: _questionImageUrl,
          videoUrl: _questionVideoUrl,
          options: optionsReq,
        );
        await _questionService.create(createReq);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo mới thành công'), backgroundColor: Colors.green));
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi gọi API: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Cập nhật Câu hỏi' : 'Thêm Câu hỏi mới'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGeneralInfoSection(),
                  const Divider(height: 48, thickness: 1.5),
                  _buildOptionsSection(),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSubmitting || _isUploadingMedia ? null : _submitForm,
                      child: _isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isEditMode ? 'LƯU CẬP NHẬT' : 'TẠO CÂU HỎI', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Hiển thị Overlay Loading khi đang upload hình/video
          if (_isUploadingMedia)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  margin: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Đang tải file..."),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- PHẦN 1: THÔNG TIN CÂU HỎI CHÍNH ---
  Widget _buildGeneralInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("1. Thông tin chung", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<QuestionType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Loại câu hỏi (*)', border: OutlineInputBorder(), isDense: true),
                items: QuestionType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                onChanged: (v) => setState(() {
                  _selectedType = v!;
                  if (!isMediaQuestion) {
                    _questionImageUrl = null;
                    _questionVideoUrl = null;
                  }
                  _formKey.currentState?.validate();
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<QuestionLevel>(
                value: _selectedLevel,
                decoration: const InputDecoration(labelText: 'Độ khó (*)', border: OutlineInputBorder(), isDense: true),
                items: QuestionLevel.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                onChanged: (v) => setState(() => _selectedLevel = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _contentCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Nội dung câu hỏi (*)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          validator: (v) => v!.trim().isEmpty ? 'Bắt buộc nhập nội dung' : null,
        ),
        const SizedBox(height: 16),

        // Khối tải Media (Chỉ hiện nếu type là MEDIA)
        if (isMediaQuestion)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Đính kèm Media (* Bắt buộc chọn 1 trong 2):", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: _questionImageUrl != null ? Colors.green : Colors.white, foregroundColor: _questionImageUrl != null ? Colors.white : Colors.black87),
                        icon: const Icon(Icons.image),
                        label: const Text('Tải Ảnh'),
                        onPressed: () => _pickMedia(isQuestion: true, isVideo: false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: _questionVideoUrl != null ? Colors.green : Colors.white, foregroundColor: _questionVideoUrl != null ? Colors.white : Colors.black87),
                        icon: const Icon(Icons.video_file),
                        label: const Text('Tải Video'),
                        onPressed: () => _pickMedia(isQuestion: true, isVideo: true),
                      ),
                    ),
                  ],
                ),
                if (_questionImageUrl != null || _questionVideoUrl != null) ...[
                  const SizedBox(height: 8),
                  Text("Đã đính kèm: ${_questionImageUrl != null ? 'HÌNH ẢNH' : 'VIDEO'} thành công", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                ]
              ],
            ),
          ),
        
        if (isMediaQuestion) const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _scoreCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Điểm số (*)', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.star_border)),
                validator: (v) => v!.trim().isEmpty ? 'Trống' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _timeLimitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Thời gian (s) (*)', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.timer_outlined)),
                validator: (v) => v!.trim().isEmpty ? 'Trống' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _categoryIdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ID Danh mục', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.category_outlined)),
                validator: (v) => v!.trim().isEmpty ? 'Trống' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- PHẦN 2: ĐÁP ÁN (A, B, C, D) ---
  Widget _buildOptionsSection() {
    if (isEssayQuestion) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: const Center(
          child: Text("📝 Câu hỏi tự luận không cần nhập đáp án trắc nghiệm.", style: TextStyle(color: Colors.grey, fontSize: 16, fontStyle: FontStyle.italic)),
        ),
      );
    }

    bool isMediaOptions = _selectedType == QuestionType.MCQ_MEDIA;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("2. Thiết lập Đáp án", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 4),
        const Text("Tick chọn vào hình tròn bên trái để chỉ định đáp án đúng.", style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 16),
        ...List.generate(4, (index) {
          bool isCorrect = _correctOptionIndex == index;
          return Card(
            elevation: isCorrect ? 2 : 0,
            color: isCorrect ? Colors.green.shade50 : Colors.white,
            shape: RoundedRectangleBorder(
              border: Border.all(color: isCorrect ? Colors.green : Colors.grey.shade300, width: isCorrect ? 2 : 1),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Radio<int>(
                    value: index,
                    groupValue: _correctOptionIndex,
                    activeColor: Colors.green,
                    onChanged: (val) => setState(() => _correctOptionIndex = val!),
                  ),
                  Text("${_labels[index]}.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isCorrect ? Colors.green : Colors.black87)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: isMediaOptions ? _buildImageOptionField(index) : _buildTextOptionField(index),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTextOptionField(int index) {
    return TextFormField(
      controller: _optionTextCtrls[index],
      decoration: InputDecoration(
        hintText: 'Nhập nội dung đáp án ${_labels[index]}...',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
    );
  }

  Widget _buildImageOptionField(int index) {
    final imageUrl = _optionImageUrls[index];
    bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    
    return Row(
      children: [
        Expanded(
          child: Text(
            hasImage ? '✅ Đã tải ảnh' : '❌ Chưa có ảnh',
            style: TextStyle(color: hasImage ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _pickMedia(isQuestion: false, optionIndex: index),
          icon: const Icon(Icons.upload, size: 18),
          label: const Text("Chọn Ảnh"),
          style: OutlinedButton.styleFrom(
            foregroundColor: hasImage ? Colors.black87 : Colors.blue,
          ),
        ),
      ],
    );
  }
}