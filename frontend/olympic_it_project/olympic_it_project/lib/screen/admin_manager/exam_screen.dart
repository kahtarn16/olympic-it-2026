import 'package:flutter/material.dart';
import 'package:olympic_it_project/core/storage_token.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/create_exam_request.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/exam_response.dart';
import 'package:olympic_it_project/dto/admin_manager/exam/update_exam_request.dart';
import 'package:olympic_it_project/screen/admin_manager/exam_detail_screen.dart';
import 'package:olympic_it_project/service/exam_service.dart';
import 'package:olympic_it_project/utils/error_snackbar.dart';

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

  // ✨ Hàm format thời gian chuẩn đẹp và an toàn
  String _formatDateTime(String? rawDateTime) {
    if (rawDateTime == null || rawDateTime.isEmpty) return '---';
    try {
      final DateTime parsedDate = DateTime.parse(rawDateTime).toLocal();
      final String hour = parsedDate.hour.toString().padLeft(2, '0');
      final String minute = parsedDate.minute.toString().padLeft(2, '0');
      final String day = parsedDate.day.toString().padLeft(2, '0');
      final String month = parsedDate.month.toString().padLeft(2, '0');
      final String year = parsedDate.year.toString();

      return '$hour:$minute - $day/$month/$year';
    } catch (e) {
      return rawDateTime;
    }
  }

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
    _scrollController.dispose();
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

  // ✨ Form Dialog: Nút bấm bự rõ ràng, chuẩn kích thước lớn
  Future<void> _showExamDialog({ExamResponse? exam}) async {
    final isEdit = exam != null;
    final nameController = TextEditingController(text: exam?.name ?? '');
    bool shuffle = exam?.shuffleOption ?? false;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: isEdit
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF3B82F6),
                                            Color(0xFF1D4ED8),
                                          ],
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFFF59E0B),
                                            Color(0xFFD97706),
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isEdit
                                      ? Icons.mode_edit_outline_rounded
                                      : Icons.post_add_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                isEdit ? 'Chỉnh sửa đề thi' : 'Tạo đề thi mới',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          TextField(
                            controller: nameController,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Tên đề thi',
                              labelStyle: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: CheckboxListTile(
                              value: shuffle,
                              title: const Text(
                                'Trộn câu hỏi khi thi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                  fontSize: 14,
                                ),
                              ),
                              activeColor: const Color(0xFF3B82F6),
                              checkboxShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              onChanged: (value) {
                                setStateDialog(() {
                                  shuffle = value ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Hệ thống nút bấm bự rõ ràng, bấm cực êm
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ), // Cao rộng rãi
                                    side: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    "HỦY BỎ",
                                    style: TextStyle(
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2563EB),
                                        Color(0xFF1D4ED8),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF2563EB,
                                        ).withOpacity(0.25),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (nameController.text.trim().isEmpty)
                                        return;

                                      try {
                                        if (isEdit) {
                                          await _examService.update(
                                            exam.id,
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

                                        if (context.mounted)
                                          Navigator.pop(context);
                                        _loadData();
                                      } catch (e) {
                                        if (context.mounted)
                                          ErrorSnackbar.showError(context, e);
                                      }
                                    },
                                    child: Text(
                                      isEdit ? "LƯU LẠI" : "TẠO NGAY",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ✨ Hộp thoại xác nhận xóa đề thi - Hệ thống nút to dễ nhấn
  Future<void> _confirmDelete(int examId) async {
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade700],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Xóa đề thi này?",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Hệ thống sẽ gỡ bỏ hoàn toàn đề thi này. Bạn chắc chắn muốn thực hiện hành động?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(
                                color: Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              "HỦY BỎ",
                              style: TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade500,
                                  Colors.red.shade700,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "XÓA NGAY",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    try {
      await _examService.delete(examId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Xóa đề thi thành công',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
      }
    } catch (e) {
      if (mounted) ErrorSnackbar.showError(context, e);
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
        title: const Text(
          'Hệ thống Đề thi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: _loadData,
          ),
        ],
      ),
      // FAB Extended với nút bấm cực to rõ ràng
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showExamDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          label: const Text(
            'THÊM ĐỀ THI MỚI',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      // SỬA LỖI QUAN TRỌNG: Gắn đúng hàm _buildBody() vào body của Scaffold
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _exams.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade400,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Hệ thống gặp sự cố:\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text(
                  'Tải lại dữ liệu',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_turned_in_outlined,
                color: Colors.grey.shade400,
                size: 64,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Kho dữ liệu đề thi đang trống.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _showExamDialog(),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Khởi tạo đề ngay',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: const Color(0xFF3B82F6),
          onRefresh: _loadData,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: _exams.length + (_isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index >= _exams.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  ),
                );
              }

              final exam = _exams[index];

              final bool isActive =
                  exam.status.toUpperCase() == 'ACTIVE' ||
                  exam.status == 'Đang mở';
              final // Định nghĩa màu nền Gradient riêng cho từng trạng thái cụ thể
              List<Color>
              statusGradients;
              switch (exam.status.toUpperCase()) {
                case 'RUNNING':
                  statusGradients = [
                    const Color(0xFF10B981),
                    const Color(0xFF059669),
                  ]; // Xanh lá
                  break;
                case 'WAITING':
                  statusGradients = [
                    const Color(0xFFF59E0B),
                    const Color(0xFFD97706),
                  ]; // Màu cam
                  break;
                default:
                  statusGradients = [
                    const Color(0xFF64748B),
                    const Color(0xFF475569),
                  ]; // Màu xám mặc định
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF1E293B).withOpacity(0.01),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExamDetailScreen(examId: exam.id),
                        ),
                      );
                      _loadData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.article_rounded,
                                  color: Color(0xFF3B82F6),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  exam.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                    height: 1.3,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: statusGradients,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  exam.status.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: exam.shuffleOption
                                      ? const Color(0xFFFFF7ED)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: exam.shuffleOption
                                        ? const Color(0xFFFFEDD5)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.shuffle_rounded,
                                      size: 12,
                                      color: exam.shuffleOption
                                          ? const Color(0xFFEA580C)
                                          : const Color(0xFF475569),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      exam.shuffleOption
                                          ? 'TRỘN ĐỀ'
                                          : 'MẶC ĐỊNH',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: exam.shuffleOption
                                            ? const Color(0xFFEA580C)
                                            : const Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(
                              color: Color(0xFFF1F5F9),
                              height: 1,
                              thickness: 1.2,
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 👑 Tên Admin to, đậm rõ ràng
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.account_box_rounded,
                                          size: 16,
                                          color: Color(0xFF1E293B),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            exam.createdBy,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              color: Color(0xFF0F172A),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // ⏰ Thời gian bự và đã qua bộ lọc Format chuẩn sạch đẹp
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.watch_later_rounded,
                                          size: 14,
                                          color: Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatDateTime(exam.createdAt),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF475569),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Nút Sửa/Xóa trong card tăng diện tích chạm, nâng icon lên 22 cực kỳ to nhạy
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showExamDialog(exam: exam),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF2563EB,
                                        ).withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit_note_rounded,
                                        color: Color(0xFF2563EB),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => _confirmDelete(exam.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete_sweep_rounded,
                                        color: Colors.red,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (_isLoading && _exams.isNotEmpty)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              color: Color(0xFF2563EB),
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
  }
}
