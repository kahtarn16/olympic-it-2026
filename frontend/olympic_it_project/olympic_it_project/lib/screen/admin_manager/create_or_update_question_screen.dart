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
import 'package:olympic_it_project/utils/error_snackbar.dart';

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
      _questionVideoFile != null ||
      (_questionImageUrl != null && _questionImageUrl!.isNotEmpty) ||
      (_questionVideoUrl != null && _questionVideoUrl!.isNotEmpty);

  bool get _hasBothQuestionMedia =>
      (_questionImageFile != null ||
          (_questionImageUrl != null && _questionImageUrl!.isNotEmpty)) &&
      (_questionVideoFile != null ||
          (_questionVideoUrl != null && _questionVideoUrl!.isNotEmpty));

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.MCQ_TEXT:
        return 'Trắc nghiệm chữ (MCQ)';
      case QuestionType.MCQ_MEDIA:
        return 'Trắc nghiệm ảnh/video';
      case QuestionType.ESSAY_TEXT:
        return 'Tự luận chữ';
      case QuestionType.ESSAY_MEDIA:
        return 'Tự luận ảnh/video';
      default:
        return type.name;
    }
  }

  String _getQuestionLevelLabel(QuestionLevel level) {
    switch (level) {
      case QuestionLevel.EASY:
        return 'Dễ';
      case QuestionLevel.MEDIUM:
        return 'Trung bình';
      case QuestionLevel.HARD:
        return 'Khó';
      default:
        return level.name;
    }
  }

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
      ErrorSnackbar.showError(context, e);
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
      ErrorSnackbar.showError(context, e);
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

      await Future.delayed(const Duration(seconds: 1));

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
          content: Text(
            'Tải file thành công!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorSnackbar.showError(context, 'Lỗi tải file: $e');
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
      ErrorSnackbar.showError(context, 'Tải media thất bại: $e');
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ErrorSnackbar.showError(context, 'Lưu thất bại: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  InputDecoration _customInputDecoration({
    required String labelText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        color: Color(0xFF64748B),
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      filled: true,
      fillColor:
          Colors.white, // Đổi ruột ô nhập liệu sang trắng tinh cho sáng sủa
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: const Color(0xFF2563EB), size: 20)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      alignLabelWithHint: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        centerTitle: true,
        title: Text(
          isEditMode ? 'Chỉnh sửa câu hỏi' : 'Tạo câu hỏi mới',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGeneralCard(),
                  if (isMediaQuestion) ...[
                    const SizedBox(height: 14),
                    _buildMediaCard(),
                  ],
                  if (isMcqQuestion) ...[
                    const SizedBox(height: 14),
                    _buildOptionsCard(),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed:
                          _isSubmitting || _isUploadingMedia || _isLoading
                          ? null
                          : _submitForm,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              isEditMode ? 'LƯU CẬP NHẬT' : 'TẠO CÂU HỎI',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isLoading || _isUploadingMedia)
            Container(
              color: const Color(0xFF0F172A).withOpacity(0.4),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF2563EB),
                          strokeWidth: 4,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isLoading
                              ? 'Đang tải thông tin...'
                              : 'Đang xử lý...',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
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
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin câu hỏi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<QuestionType>(
                    value: _selectedType,
                    dropdownColor: Colors.white,
                    isExpanded:
                        true, // 👈 Thêm cái này để Dropdown chiếm hết không gian ô
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      fontSize: 14,
                    ),
                    decoration: _customInputDecoration(
                      labelText: 'Loại câu hỏi',
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return QuestionType.values.map<Widget>((
                        QuestionType type,
                      ) {
                        // 👈 Bọc Expanded ở đây để chữ dài tự động xuống dòng hoặc cắt bớt, không làm sập layout Row
                        return Expanded(
                          child: Text(
                            _getQuestionTypeLabel(type),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList();
                    },
                    items: QuestionType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                _getQuestionTypeLabel(type),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
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
                    dropdownColor: Colors.white,
                    isExpanded:
                        true, // 👈 Thêm cái này để Dropdown chiếm hết không gian ô
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      fontSize: 14,
                    ),
                    decoration: _customInputDecoration(labelText: 'Độ khó'),
                    selectedItemBuilder: (BuildContext context) {
                      return QuestionLevel.values.map<Widget>((
                        QuestionLevel level,
                      ) {
                        // 👈 Bọc Expanded tương tự cho ô Độ khó
                        return Expanded(
                          child: Text(
                            _getQuestionLevelLabel(level),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList();
                    },
                    items: QuestionLevel.values
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                _getQuestionLevelLabel(level),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: _customInputDecoration(labelText: 'Nội dung câu hỏi'),
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'Vui lòng nhập nội dung.';
                return null;
              },
            ),
            if (isEssayQuestion) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _answerCtrl,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _customInputDecoration(labelText: 'Đáp án gợi ý'),
                validator: (value) {
                  if (isEssayQuestion &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Tự luận cần có đáp án gợi ý.';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            _buildCategoryField(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _scoreCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: _customInputDecoration(
                      labelText: 'Điểm',
                      prefixIcon: Icons.star_rounded,
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: _customInputDecoration(
                      labelText: 'Thời gian (s)',
                      prefixIcon: Icons.timer_rounded,
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
      dropdownColor:
          Colors.white, // ✨ Đã sửa: Nền danh sách xổ xuống màu trắng sạch sẽ
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF64748B),
      ),
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
        fontSize: 14,
      ),
      decoration: _customInputDecoration(
        labelText: 'Danh mục',
        prefixIcon: Icons.folder_special_rounded,
      ),
      selectedItemBuilder: (BuildContext context) {
        return _categories.map<Widget>((cat) {
          return Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis);
        }).toList();
      },
      items: _categories
          .map(
            (category) => DropdownMenuItem(
              value: category.id,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
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
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Media',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_hasQuestionMedia) ...[
              _buildQuestionMediaPreview(),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        _hasBothQuestionMedia ||
                            _questionVideoUrl != null ||
                            _questionVideoFile != null
                        ? null
                        : () => _pickMedia(isQuestion: true, isVideo: false),
                    icon: const Icon(Icons.image_rounded, size: 18),
                    label: const Text(
                      'Chọn ảnh',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0FDF4),
                      foregroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        _hasBothQuestionMedia ||
                            _questionImageUrl != null ||
                            _questionImageFile != null
                        ? null
                        : () => _pickMedia(isQuestion: true, isVideo: true),
                    icon: const Icon(Icons.video_collection_rounded, size: 18),
                    label: const Text(
                      'Chọn video',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                            Uri.tryParse(_questionImageUrl!)?.hasScheme == true)
                      ? Image.network(
                          _questionImageUrl!,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : (_questionImageUrl != null &&
                            _questionImageUrl!.isNotEmpty)
                      ? Image.file(
                          File(_questionImageUrl!),
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox.shrink(),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preview video',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        videoName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Positioned(
          right: 6,
          top: 6,
          child: CircleAvatar(
            backgroundColor: Colors.red.shade50,
            radius: 16,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.red,
                size: 18,
              ),
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
        ),
      ],
    );
  }

  Widget _buildOptionsCard() {
    final isMediaMode = _isOptionMedia;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Đáp án trắc nghiệm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() {
                        _isOptionMedia = false;
                        _resetOptions();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isMediaMode
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !isMediaMode
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Dạng chữ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: !isMediaMode
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() {
                        _isOptionMedia = true;
                        _resetOptions();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isMediaMode
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isMediaMode
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Dạng ảnh',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isMediaMode
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chọn đáp án đúng bằng vòng tròn bên trái.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(4, (index) {
              final isCorrect = _correctOptionIndex == index;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isCorrect ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCorrect
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE2E8F0),
                    width: isCorrect ? 2 : 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: _correctOptionIndex,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _correctOptionIndex = value);
                        },
                      ),
                      Text(
                        _labels[index],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCorrect
                              ? const Color(0xFF16A34A)
                              : Colors.black,
                          fontSize: 15,
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
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Nội dung đáp án ${_labels[index]}',
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
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
                color: const Color(0xFFF8FAFC),
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
            child: Text(
              'Chưa có ảnh',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              onPressed: () =>
                  _pickMedia(isQuestion: false, optionIndex: index),
              icon: const Icon(
                Icons.upload_file,
                size: 16,
                color: Color(0xFF475569),
              ),
              label: const Text(
                'Tải ảnh',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(height: 2),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                tooltip: 'Xóa ảnh đáp án',
                onPressed: () {
                  setState(() {
                    _optionImageUrls[index] = null;
                  });
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}
