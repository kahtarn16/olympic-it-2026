import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:olympic_it_project/core/question_level.dart';
import 'package:olympic_it_project/core/question_type.dart';
import 'package:olympic_it_project/dto/admin_manager/category/category_response.dart';
import 'package:olympic_it_project/dto/admin_manager/question/create_question_option_request.dart';
import 'package:olympic_it_project/dto/admin_manager/question/create_question_request.dart';
import 'package:olympic_it_project/dto/admin_manager/question/update_question_request.dart';
import 'package:olympic_it_project/core/api_client.dart';
import 'package:olympic_it_project/service/category_service.dart';
import 'package:olympic_it_project/service/question_service.dart';
import 'package:olympic_it_project/service/upload_service.dart';

class CreateOrUpdateQuestionScreen extends StatefulWidget {
  final int? questionId;

  const CreateOrUpdateQuestionScreen({super.key, this.questionId});

  @override
  State<CreateOrUpdateQuestionScreen> createState() =>
      _CreateOrUpdateQuestionScreenState();
}

class _CreateOrUpdateQuestionScreenState
    extends State<CreateOrUpdateQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _questionService = QuestionService();
  final _categoryService = CategoryService();
  final _uploadService = UploadService();

  final _contentCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController(text: '10');
  final _timeLimitCtrl = TextEditingController(text: '60');
  late final List<TextEditingController> _optionTextCtrls;

  List<CategoryResponse> _categories = [];
  int? _selectedCategoryId;
  QuestionType _selectedType = QuestionType.MCQ_TEXT;
  QuestionLevel _selectedLevel = QuestionLevel.EASY;

  String? _questionImageUrl;
  String? _questionVideoUrl;
  File? _questionImageFile;
  File? _questionVideoFile;

  final List<String> _labels = ['A', 'B', 'C', 'D'];
  final List<String?> _optionImageUrls = List.filled(4, null);
  bool _isOptionMedia = false;
  int _correctOptionIndex = 0;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isUploadingMedia = false;

  bool get isEditMode => widget.questionId != null;
  bool get isMediaQuestion =>
      _selectedType == QuestionType.MCQ_MEDIA ||
      _selectedType == QuestionType.ESSAY_MEDIA;
  bool get isEssayQuestion =>
      _selectedType == QuestionType.ESSAY_TEXT ||
      _selectedType == QuestionType.ESSAY_MEDIA;
  bool get isMcqQuestion =>
      _selectedType == QuestionType.MCQ_TEXT ||
      _selectedType == QuestionType.MCQ_MEDIA;

  bool get _hasQuestionMedia =>
    _questionImageFile != null ||
    (_questionImageUrl != null && _questionImageUrl!.trim().isNotEmpty) ||
    _questionVideoFile != null ||
    (_questionVideoUrl != null && _questionVideoUrl!.trim().isNotEmpty);

  bool get _hasBothQuestionMedia =>
      (_questionImageFile != null ||
          (_questionImageUrl != null && _questionImageUrl!.isNotEmpty)) &&
      (_questionVideoFile != null ||
          (_questionVideoUrl != null && _questionVideoUrl!.isNotEmpty));

  @override
  void initState() {
    super.initState();
    _optionTextCtrls = List.generate(4, (_) => TextEditingController());
    _loadCategories();
    if (isEditMode) {
      _loadQuestionDetail();
    }
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _answerCtrl.dispose();
    _scoreCtrl.dispose();
    _timeLimitCtrl.dispose();
    for (final ctrl in _optionTextCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getAll();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectedCategoryId =
            _selectedCategoryId ??
            (categories.isNotEmpty ? categories.first.id : null);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không tải được danh mục: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadQuestionDetail() async {
    if (widget.questionId == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final detail = await _questionService.getDetail(widget.questionId!);
      if (!mounted) return;
      setState(() {
        _selectedType = detail.type;
        _selectedLevel = detail.level;
        _contentCtrl.text = detail.content;
        _answerCtrl.text = detail.answer ?? '';
        _scoreCtrl.text = detail.score.toString();
        _timeLimitCtrl.text = detail.timeLimit.toString();
        _selectedCategoryId = detail.categoryId;
        _questionImageUrl = detail.imageUrl;
        _questionVideoUrl = detail.videoUrl;
        _questionImageFile = null;
        _questionVideoFile = null;
        final hasOptionImages = detail.options.any(
          (option) => option.imageUrl != null && option.imageUrl!.isNotEmpty,
        );
        _isOptionMedia = hasOptionImages;
        _resetOptions();

        for (var i = 0; i < detail.options.length && i < 4; i++) {
          final option = detail.options[i];
          if (hasOptionImages) {
            _optionImageUrls[i] = option.imageUrl;
          } else {
            _optionTextCtrls[i].text = option.contentText;
          }
          if (option.isCorrect) {
            _correctOptionIndex = i;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không tải được chi tiết: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetOptions() {
    for (final ctrl in _optionTextCtrls) {
      ctrl.clear();
    }
    for (var i = 0; i < _optionImageUrls.length; i++) {
      _optionImageUrls[i] = null;
    }
    _correctOptionIndex = 0;
  }

  Future<void> _pickMedia({
    required bool isQuestion,
    bool isVideo = false,
    int? optionIndex,
  }) async {
    try {
      final XFile? file = isVideo
          ? await _picker.pickVideo(source: ImageSource.gallery)
          : await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      setState(() {
        _isUploadingMedia = true;
      });

      if (!mounted) return;
      setState(() {
        if (isQuestion) {
          if (isVideo) {
            _questionVideoFile = File(file.path);
            _questionVideoUrl = null;
            _questionImageFile = null;
            _questionImageUrl = null;
          } else {
            _questionImageFile = File(file.path);
            _questionImageUrl = null;
            _questionVideoFile = null;
            _questionVideoUrl = null;
          }
        } else if (optionIndex != null) {
          _optionImageUrls[optionIndex] = file.path;
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tải file thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
      });
    }
  }

  Future<void> _uploadPendingMedia() async {
    if (_questionImageFile != null) {
      final uploaded = await _uploadService.uploadImage(
        _questionImageFile!.path,
      );
      _questionImageUrl = uploaded;
      _questionImageFile = null;
    }

    if (_questionVideoFile != null) {
      final uploaded = await _uploadService.uploadVideo(
        _questionVideoFile!.path,
      );
      _questionVideoUrl = uploaded;
      _questionVideoFile = null;
    }

    if (_isOptionMedia) {
      for (var i = 0; i < _optionImageUrls.length; i++) {
        final imageUrl = _optionImageUrls[i];
        if (imageUrl == null || imageUrl.trim().isEmpty) continue;
        if (!imageUrl.startsWith('http') && !imageUrl.startsWith('/uploads/')) {
          final uploaded = await _uploadService.uploadImage(imageUrl);
          _optionImageUrls[i] = uploaded;
        }
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingMedia || _isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đợi quá trình tải/xử lý hoàn tất'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chọn danh mục trước khi lưu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isMediaQuestion && !_hasQuestionMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Media question cần ít nhất 1 ảnh hoặc 1 video.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_hasBothQuestionMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chỉ chọn 1 trong 2: ảnh hoặc video cho câu hỏi media.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isEssayQuestion && _answerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Câu hỏi tự luận cần ít nhất một đáp án gợi ý.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isMcqQuestion) {
      final requiresTextOptions = !_isOptionMedia;
      for (var i = 0; i < 4; i++) {
        if (requiresTextOptions) {
          if (_optionTextCtrls[i].text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đáp án ${_labels[i]} không được để trống.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } else {
          if (_optionImageUrls[i] == null ||
              _optionImageUrls[i]!.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Vui lòng thêm ảnh cho đáp án ${_labels[i]}.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
      }
    }

    setState(() {
      _isSubmitting = true;
      _isUploadingMedia = true;
    });

    try {
      await _uploadPendingMedia();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isUploadingMedia = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tải media thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
        });
      }
    }

    final options = isMcqQuestion
        ? List.generate(
            4,
            (index) => CreateQuestionOptionRequest(
              label: _labels[index],
              contentText: !_isOptionMedia
                  ? _optionTextCtrls[index].text.trim()
                  : '',
              imageUrl: _isOptionMedia ? _optionImageUrls[index] : null,
              isCorrect: _correctOptionIndex == index,
            ),
          )
        : null;

    final imageUrl = _questionImageFile?.path ?? _questionImageUrl;
    final videoUrl = _questionVideoFile?.path ?? _questionVideoUrl;

    try {
      final requestType = _selectedType;

      if (isEditMode) {
        final updateReq = UpdateQuestionRequest(
          content: _contentCtrl.text.trim(),
          type: requestType,
          level: _selectedLevel,
          answer: _answerCtrl.text.trim().isEmpty
              ? null
              : _answerCtrl.text.trim(),
          score: int.parse(_scoreCtrl.text.trim()),
          categoryId: _selectedCategoryId!,
          timeLimit: int.parse(_timeLimitCtrl.text.trim()),
          imageUrl: imageUrl,
          videoUrl: videoUrl,
          options: options,
        );
        await _questionService.update(widget.questionId!, updateReq);
      } else {
        final createReq = CreateQuestionRequest(
          content: _contentCtrl.text.trim(),
          type: requestType,
          level: _selectedLevel,
          answer: _answerCtrl.text.trim().isEmpty
              ? null
              : _answerCtrl.text.trim(),
          score: int.parse(_scoreCtrl.text.trim()),
          categoryId: _selectedCategoryId!,
          timeLimit: int.parse(_timeLimitCtrl.text.trim()),
          imageUrl: imageUrl,
          videoUrl: videoUrl,
          options: options,
        );
        await _questionService.create(createReq);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode ? 'Cập nhật thành công!' : 'Tạo câu hỏi thành công!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lưu thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Chỉnh sửa câu hỏi' : 'Tạo câu hỏi mới'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGeneralCard(),
                  const SizedBox(height: 12),
                  if (isMediaQuestion) _buildMediaCard(),
                  if (isMcqQuestion) ...[
                    const SizedBox(height: 12),
                    _buildOptionsCard(),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          _isSubmitting || _isUploadingMedia || _isLoading
                          ? null
                          : _submitForm,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isEditMode ? 'LƯU CẬP NHẬT' : 'TẠO CÂU HỎI'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isLoading || _isUploadingMedia)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  margin: EdgeInsets.all(24),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Đang xử lý...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGeneralCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Thông tin câu hỏi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<QuestionType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Loại câu hỏi',
                      border: OutlineInputBorder(),
                    ),
                    items: QuestionType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.name),
                          ),
                        )
                        .toList(),
                    onChanged: (type) {
                      if (type == null) return;
                      setState(() {
                        _selectedType = type;
                        _resetOptions();
                        _questionImageFile = null;
                        _questionImageUrl = null;
                        _questionVideoFile = null;
                        _questionVideoUrl = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<QuestionLevel>(
                    value: _selectedLevel,
                    decoration: const InputDecoration(
                      labelText: 'Độ khó',
                      border: OutlineInputBorder(),
                    ),
                    items: QuestionLevel.values
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(level.name),
                          ),
                        )
                        .toList(),
                    onChanged: (level) {
                      if (level == null) return;
                      setState(() => _selectedLevel = level);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentCtrl,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Nội dung câu hỏi',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'Vui lòng nhập nội dung.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (isEssayQuestion)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _answerCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Đáp án gợi ý',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (isEssayQuestion &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Tự luận cần có đáp án gợi ý.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            _buildCategoryField(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _scoreCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Điểm',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Nhập điểm.';
                      if (int.tryParse(value.trim()) == null)
                        return 'Phải là số nguyên.';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _timeLimitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Thời gian (s)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Nhập thời gian.';
                      if (int.tryParse(value.trim()) == null)
                        return 'Phải là số nguyên.';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<int>(
      value: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Danh mục',
        border: OutlineInputBorder(),
      ),
      items: _categories
          .map(
            (category) => DropdownMenuItem(
              value: category.id,
              child: Text(category.name),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
      validator: (value) {
        if (value == null) return 'Chọn danh mục.';
        return null;
      },
    );
  }

  Widget _buildMediaCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Media',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_hasQuestionMedia) _buildQuestionMediaPreview(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _hasBothQuestionMedia ||
                            _questionVideoUrl != null ||
                            _questionVideoFile != null
                        ? null
                        : () => _pickMedia(isQuestion: true, isVideo: false),
                    icon: const Icon(Icons.image),
                    label: const Text('Chọn ảnh'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _hasBothQuestionMedia ||
                            _questionImageUrl != null ||
                            _questionImageFile != null
                        ? null
                        : () => _pickMedia(isQuestion: true, isVideo: true),
                    icon: const Icon(Icons.video_file),
                    label: const Text('Chọn video'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionMediaPreview() {
    final hasImage = _questionImageFile != null || _questionImageUrl != null;
    final videoName =
        _questionVideoFile?.path.split('/').last ??
        _questionVideoUrl?.split('/').last ??
        '';

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade100,
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _questionImageFile != null
                      ? Image.file(
                          _questionImageFile!,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : (_questionImageUrl != null &&
                            _questionImageUrl!.isNotEmpty)
                      ? Image.network(
                          _questionImageUrl!.startsWith('http')
                              ? _questionImageUrl!
                              : '${ApiClient.host}${_questionImageUrl!}',
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        )
                      : const SizedBox.shrink(),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview video',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(videoName, style: const TextStyle(fontSize: 14)),
                  ],
                ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: () {
              setState(() {
                _questionImageFile = null;
                _questionVideoFile = null;
                _questionImageUrl = null;
                _questionVideoUrl = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsCard() {
    final isMediaMode = _isOptionMedia;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Đáp án trắc nghiệm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isOptionMedia = false;
                        _resetOptions();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !isMediaMode
                          ? Colors.blue
                          : Colors.white,
                      foregroundColor: !isMediaMode
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: const Text('Dạng chữ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isOptionMedia = true;
                        _resetOptions();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isMediaMode ? Colors.blue : Colors.white,
                      foregroundColor: isMediaMode
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: const Text('Dạng ảnh'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Chọn đáp án đúng bằng vòng tròn bên trái.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...List.generate(4, (index) {
              final isCorrect = _correctOptionIndex == index;
              return Card(
                color: isCorrect ? Colors.green.shade50 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCorrect ? Colors.green : Colors.grey.shade300,
                    width: isCorrect ? 2 : 1,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: _correctOptionIndex,
                        activeColor: Colors.green,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _correctOptionIndex = value);
                        },
                      ),
                      Text(
                        '${_labels[index]}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCorrect ? Colors.green : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: isMediaMode
                            ? _buildImageOptionField(index)
                            : _buildTextOptionField(index),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTextOptionField(int index) {
    return TextFormField(
      controller: _optionTextCtrls[index],
      decoration: InputDecoration(
        hintText: 'Nội dung đáp án ${_labels[index]}',
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildImageOptionField(int index) {
    final imageUrl = _optionImageUrls[index];
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Row(
      children: [
        if (hasImage)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 70,
                color: Colors.grey.shade100,
                child:
                    imageUrl.startsWith('http') ||
                        imageUrl.startsWith('/uploads/')
                    ? Image.network(
                        imageUrl.startsWith('http')
                            ? imageUrl
                            : '${ApiClient.host}$imageUrl',
                        fit: BoxFit.cover,
                      )
                    : Image.file(File(imageUrl), fit: BoxFit.cover),
              ),
            ),
          )
        else
          const Expanded(
            child: Text('Chưa có ảnh', style: TextStyle(color: Colors.grey)),
          ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  _pickMedia(isQuestion: false, optionIndex: index),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Tải ảnh'),
            ),
            if (hasImage)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Xóa ảnh đáp án',
                onPressed: () {
                  setState(() {
                    _optionImageUrls[index] = null;
                  });
                },
              ),
          ],
        ),
      ],
    );
  }
}
