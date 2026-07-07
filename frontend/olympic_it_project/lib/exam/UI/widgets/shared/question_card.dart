import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

// Widget hiển thị khối đề bài — dùng chung cho trắc nghiệm và tự luận
// Tự xử lý 3 trường hợp media:
//   1. Chỉ có text (imageAssetPath = null, videoUrl = null)
//   2. Có ảnh     (imageAssetPath != null)
//   3. Có video   (videoUrl != null)
//
// TODO: Khi có server — imageAssetPath sẽ đổi thành imageUrl (String URL)
//                      — videoUrl sẽ là URL stream từ server
class QuestionCard extends StatelessWidget {
  // Nội dung đề bài — bắt buộc phải có
  final String questionText;

  // TODO: REPLACE WITH API — hiện đang dùng asset path local
  // Khi có server: đổi thành imageUrl và dùng Image.network() thay Image.asset()
  final String? imageAssetPath;

  // TODO: REPLACE WITH API — URL video stream từ server
  // Khi có server: truyền URL vào đây và dùng package video_player + chewie
  final String? videoUrl;

  const QuestionCard({
    super.key,
    required this.questionText,
    this.imageAssetPath,
    this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── NỘI DUNG ĐỀ BÀI ─────────────────────────────────────────────
          Text(
            questionText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.4, // line height cho dễ đọc
            ),
          ),

          // ── MEDIA: ẢNH ──────────────────────────────────────────────────
          // Chỉ hiển thị nếu có imageAssetPath, videoUrl được ưu tiên kiểm tra trước
          if (imageAssetPath != null && videoUrl == null) ...[
            const SizedBox(height: 16),
            _QuestionImage(assetPath: imageAssetPath!),
          ],

          // ── MEDIA: VIDEO ─────────────────────────────────────────────────
          // TODO: REPLACE WITH API — thay _QuestionVideoPlaceholder
          // bằng _QuestionVideo(url: videoUrl!) khi tích hợp video_player
          if (videoUrl != null) ...[
            const SizedBox(height: 16),
            _QuestionVideoPlayer(videoUrl: videoUrl!),
          ],
        ],
      ),
    );
  }
}

// ── WIDGET ẢNH ───────────────────────────────────────────────────────────────
// Hiển thị ảnh thu nhỏ, nhấn vào mở Dialog fullscreen
// TODO: REPLACE WITH API — đổi Image.asset → Image.network khi có server
class _QuestionImage extends StatelessWidget {
  final String assetPath;

  const _QuestionImage({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Nhấn vào ảnh → mở Dialog xem ảnh to
      onTap: () => _showImageDialog(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          assetPath,
          width: double.infinity,
          // Giữ nguyên tỉ lệ ảnh, không bị méo
          fit: BoxFit.contain,
          // Hiển thị placeholder nếu ảnh không load được
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 180,
              color: const Color(0xFF2A2A2A),
              alignment: Alignment.center,
              child: const Text(
                '[Ảnh minh họa]',
                style: TextStyle(color: Colors.white70),
              ),
            );
          },
        ),
      ),
    );
  }

  // Mở Dialog hiển thị ảnh fullscreen khi người dùng nhấn vào
  void _showImageDialog(BuildContext context) {
    showDialog(
      context: context,
      // Nhấn ra ngoài để đóng Dialog
      barrierDismissible: true,
      builder: (_) => Dialog(
        // Bỏ padding mặc định của Dialog để ảnh chiếm toàn bộ
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black,
        child: GestureDetector(
          // Nhấn vào ảnh trong Dialog cũng đóng lại
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            // Cho phép zoom ảnh bằng 2 ngón tay
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              assetPath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ── WIDGET VIDEO PLACEHOLDER ─────────────────────────────────────────────────
// Placeholder tạm thời cho đến khi tích hợp video_player + chewie
// TODO: REPLACE WITH API — xoá class này, thay bằng _QuestionVideo dùng video_player
class _QuestionVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _QuestionVideoPlayer({required this.videoUrl});

  @override
  State<_QuestionVideoPlayer> createState() => _QuestionVideoPlayerState();
}

class _QuestionVideoPlayerState extends State<_QuestionVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        autoPlay: false,
        looping: false,

        // ── ĐÃ FIX CẤU HÌNH XOAY MÀN HÌNH CHUẨN UX ───────────────────────────
        // 1. Khi VÀO phóng to: Ép hoặc cho phép xoay ngang màn hình
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        
        // 2. Khi THOÁT phóng to: Ép màn hình quay trở lại chiều dọc cố định
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
        ],
        // ─────────────────────────────────────────────────────────────────────

        errorBuilder: (context, errorMessage) {
          return const Center(
            child: Text(
              'Lỗi tải video, vui lòng kiểm tra lại kết nối!',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );
      setState(() {});
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    // Giải phóng Chewie trước rồi mới tới VideoPlayer để tránh lỗi bất đồng bộ
    _chewieController?.dispose();
    _videoPlayerController.dispose();
    
    // Đảm bảo khi hủy Widget này, toàn bộ app quay về hướng dọc mặc định
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
        color: Colors.black,
        alignment: Alignment.center,
        child: const Text('Không thể phát video này', style: TextStyle(color: Colors.white)),
      );
    }

    return Container(
      height: 200, 
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
          ? Chewie(controller: _chewieController!)
          : const Center(
              child: CircularProgressIndicator(
                color: Colors.white, 
              ),
            ),
    );
  }
}