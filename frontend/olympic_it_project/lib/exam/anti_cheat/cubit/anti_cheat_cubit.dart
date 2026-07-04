import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_windowmanager_v2/flutter_windowmanager_v2.dart';
import 'package:root_checker_plus/root_checker_plus.dart';

// ════════════════════════════════════════════════════════════════════════════
// LOẠI VI PHẠM
// ════════════════════════════════════════════════════════════════════════════

enum ViolationType {
  exitApp,     // Thoát app / chuyển app khác
  screenshot,  // Cố chụp / quay màn hình
  splitScreen, // Chia đôi màn hình
}

// Chuyển enum thành chuỗi hiển thị cho người dùng
extension ViolationTypeLabel on ViolationType {
  String get label {
    switch (this) {
      case ViolationType.exitApp:
        return 'Cửa sổ đã mất focus';
      case ViolationType.screenshot:
        return 'Phát hiện chụp màn hình';
      case ViolationType.splitScreen:
        return 'Phát hiện chia đôi màn hình';
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MODEL LOG VI PHẠM
// Lưu thông tin mỗi lần vi phạm — sau này ghi lên Firebase
// ════════════════════════════════════════════════════════════════════════════

class ViolationLog {
  // TODO: REPLACE WITH API — lấy userId thật từ AuthCubit
  final String userId;

  // Loại vi phạm xảy ra
  final ViolationType type;

  // Thời điểm xảy ra vi phạm
  final DateTime time;

  // Lần vi phạm thứ mấy (1, 2, 3)
  final int violationCount;

  ViolationLog({
    required this.userId,
    required this.type,
    required this.time,
    required this.violationCount,
  });

  // Chuyển thành Map — dùng để ghi Firebase sau này
  // TODO: REPLACE WITH API — dùng map này ghi lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.label,
      'time': time.toIso8601String(),
      'violationCount': violationCount,
    };
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════════════════════

abstract class AntiCheatState {}

// Chưa bắt đầu giám sát
class AntiCheatIdle extends AntiCheatState {}

// Đang giám sát bình thường — không có vấn đề
class AntiCheatGuarding extends AntiCheatState {}

// Thiết bị không an toàn — chặn thi ngay từ đầu
class AntiCheatDeviceUnsafe extends AntiCheatState {
  final String reason;
  AntiCheatDeviceUnsafe({required this.reason});
}

// Phát hiện vi phạm — ExamScreen lắng nghe để hiện Dialog
class AntiCheatViolationDetected extends AntiCheatState {
  final ViolationLog log;
  final int totalViolations;

  // Số cơ hội còn lại
  int get remainingChances => 3 - totalViolations;

  // Hết cơ hội — tự động nộp bài không hỏi
  bool get isAutoSubmit => totalViolations >= 3;

  AntiCheatViolationDetected({
    required this.log,
    required this.totalViolations,
  });
}

// Đã nộp/khoá bài do vi phạm quá số lần
class AntiCheatSubmitted extends AntiCheatState {}

// ════════════════════════════════════════════════════════════════════════════
// CUBIT
// ════════════════════════════════════════════════════════════════════════════

class AntiCheatCubit extends Cubit<AntiCheatState>
    with WidgetsBindingObserver {
  // Tổng số lần vi phạm trong phiên thi
  int _violationCount = 0;

  // Giới hạn vi phạm — quá số này tự động khoá bài
  static const int _maxViolations = 3;

  // TODO: REPLACE WITH API — lấy userId thật từ AuthCubit
  final String _userId = 'mock_user_id';

  // Lưu toàn bộ log vi phạm — sau này gửi lên Firebase
  final List<ViolationLog> _violationLogs = [];

  // Cờ chặn xử lý inactive liên tiếp
  // Tránh tính 2 vi phạm cùng lúc khi app chuyển inactive → paused
  bool _isProcessingViolation = false;

  AntiCheatCubit() : super(AntiCheatIdle());

  // ── BẮT ĐẦU GIÁM SÁT ──────────────────────────────────────────────────

  Future<void> startGuarding() async {
    // Bước 1: Kiểm tra root/jailbreak theo từng platform
    try {
      if (Platform.isAndroid) {
        // isRootChecker() — đúng tên method của root_checker_plus trên Android
        final bool isRooted =
            (await RootCheckerPlus.isRootChecker()) ?? false;
        if (isRooted) {
          emit(AntiCheatDeviceUnsafe(
            reason: 'Thiết bị Android đã bị root.',
          ));
          return; // dừng lại, không cho thi
        }
      } else if (Platform.isIOS) {
        // isJailbreak() — method riêng cho iOS
        final bool isJailbroken =
            (await RootCheckerPlus.isJailbreak()) ?? false;
        if (isJailbroken) {
          emit(AntiCheatDeviceUnsafe(
            reason: 'Thiết bị iOS đã bị jailbreak.',
          ));
          return;
        }
      }
    } on PlatformException {
      // Không check được — cho phép thi, không chặn
      // vì lỗi platform không phải lỗi của thí sinh
    }

    // Bước 2: Chặn chụp/quay màn hình — chỉ Android
    // flutter_windowmanager_v2 không hỗ trợ iOS
    if (Platform.isAndroid) {
      await FlutterWindowManagerV2.addFlags(
        FlutterWindowManagerV2.FLAG_SECURE,
      );
    }

    // Bước 3: Reset cờ xử lý vi phạm
    _isProcessingViolation = false;

    // Bước 4: Đăng ký lắng nghe AppLifecycleState
    WidgetsBinding.instance.addObserver(this);

    emit(AntiCheatGuarding());
  }

  // ── DỪNG GIÁM SÁT (sau khi thi xong / bị khoá) ────────────────────────

  Future<void> stopGuarding() async {
    // Hủy lắng nghe AppLifecycle
    WidgetsBinding.instance.removeObserver(this);

    // Bỏ chặn chụp màn hình — chỉ Android
    if (Platform.isAndroid) {
      await FlutterWindowManagerV2.clearFlags(
        FlutterWindowManagerV2.FLAG_SECURE,
      );
    }

    emit(AntiCheatIdle());
  }

  // ── LẮNG NGHE VÒNG ĐỜI APP ────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    // Chỉ xử lý khi đang trong trạng thái giám sát
    if (state is! AntiCheatGuarding) return;

    switch (lifecycleState) {

      // App bị đẩy xuống nền — nhấn Home, chuyển app, split screen
      case AppLifecycleState.paused:
        // Nếu inactive đã tính vi phạm rồi thì không tính thêm lần nữa
        // Tránh tính 2 lần khi app đi: inactive → paused liên tiếp
        if (!_isProcessingViolation) {
          _handleViolation(ViolationType.exitApp);
        }
        // Reset cờ sau khi paused để lần sau inactive vẫn tính bình thường
        _isProcessingViolation = false;
        break;

      // App mất focus — kéo thanh thông báo, bong bóng chat đè lên
      // ✅ FIX: tính vi phạm thay vì bỏ qua như trước
      case AppLifecycleState.inactive:
        // Dùng cờ để tránh tính 2 vi phạm cùng lúc (inactive + paused)
        if (!_isProcessingViolation) {
          _isProcessingViolation = true;
          _handleViolation(ViolationType.exitApp);
        }
        break;

      // App quay lại foreground — resume giám sát bình thường
      case AppLifecycleState.resumed:
        // Reset cờ khi app quay lại
        _isProcessingViolation = false;
        // Chỉ emit Guarding nếu không đang hiện dialog vi phạm
        if (state is! AntiCheatViolationDetected) {
          emit(AntiCheatGuarding());
        }
        break;

      default:
        break;
    }
  }

  // ── PHÁT HIỆN CHIA ĐÔI MÀN HÌNH ──────────────────────────────────────
  // Gọi từ ExamScreen khi LayoutBuilder phát hiện màn hình thu nhỏ bất thường
  // TODO: REPLACE — thay bằng Platform Channel isInMultiWindowMode() cho chính xác hơn
  void onSplitScreenDetected() {
    if (state is! AntiCheatGuarding) return;
    _handleViolation(ViolationType.splitScreen);
  }

  // ── XỬ LÝ VI PHẠM TRUNG TÂM ──────────────────────────────────────────

  void _handleViolation(ViolationType type) {
    // Tăng đếm vi phạm
    _violationCount++;

    // Tạo log cho lần vi phạm này
    final ViolationLog log = ViolationLog(
      userId: _userId,
      type: type,
      time: DateTime.now(),
      violationCount: _violationCount,
    );

    // Lưu log vào danh sách local
    _violationLogs.add(log);

    // TODO: REPLACE WITH API — ghi log lên Firebase Firestore
    // FirebaseFirestore.instance.collection('violations').add(log.toMap());
    _mockLogToConsole(log);

    // Emit state để ExamScreen xử lý
    emit(AntiCheatViolationDetected(
      log: log,
      totalViolations: _violationCount,
    ));

    // Tự động khoá bài khi vi phạm đủ số lần
    if (_violationCount >= _maxViolations) {
      Future.delayed(const Duration(milliseconds: 800), () {
        emit(AntiCheatSubmitted());
      });
    }
  }

  // ── MOCK LOG ──────────────────────────────────────────────────────────
  // TODO: REPLACE WITH API — xoá hàm này khi tích hợp Firebase
  void _mockLogToConsole(ViolationLog log) {
    // ignore: avoid_print
    print(
      '[AntiCheat] Vi phạm lần ${log.violationCount}: '
      '${log.type.label} lúc ${log.time}',
    );
  }

  // ── GETTER ────────────────────────────────────────────────────────────

  // Lấy danh sách toàn bộ log — dùng để gửi server khi nộp bài
  List<ViolationLog> get allLogs => List.unmodifiable(_violationLogs);

  // Tổng số vi phạm hiện tại
  int get violationCount => _violationCount;

  // ── CLEANUP ───────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }
}