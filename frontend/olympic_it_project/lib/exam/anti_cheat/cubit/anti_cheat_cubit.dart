import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_windowmanager_v2/flutter_windowmanager_v2.dart';
import 'package:root_checker_plus/root_checker_plus.dart';

enum ViolationType {
  exitApp,
  screenshot,
  splitScreen,
}

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

class ViolationLog {
  final String userId;
  final ViolationType type;
  final DateTime time;
  final int violationCount;

  ViolationLog({
    required this.userId,
    required this.type,
    required this.time,
    required this.violationCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.label,
      'time': time.toIso8601String(),
      'violationCount': violationCount,
    };
  }
}

abstract class AntiCheatState {}

class AntiCheatIdle extends AntiCheatState {}

class AntiCheatGuarding extends AntiCheatState {}

class AntiCheatDeviceUnsafe extends AntiCheatState {
  final String reason;
  AntiCheatDeviceUnsafe({required this.reason});
}

class AntiCheatViolationDetected extends AntiCheatState {
  final ViolationLog log;
  final int totalViolations;

  int get remainingChances => 3 - totalViolations;
  bool get isAutoSubmit => totalViolations >= 3;

  AntiCheatViolationDetected({
    required this.log,
    required this.totalViolations,
  });
}

class AntiCheatSubmitted extends AntiCheatState {} // Trạng thái đã nộp/khoá bài

class AntiCheatCubit extends Cubit<AntiCheatState> with WidgetsBindingObserver {
  int _violationCount = 0;
  static const int _maxViolations = 3;
  final String _userId = 'mock_user_id';
  final List<ViolationLog> _violationLogs = [];

  AntiCheatCubit() : super(AntiCheatIdle());

  Future<void> startGuarding() async {
    try {
      if (Platform.isAndroid) {
        final bool isRooted = (await RootCheckerPlus.isRootChecker()) ?? false;
        if (isRooted) {
          emit(AntiCheatDeviceUnsafe(reason: 'Thiết bị Android đã bị root.'));
          return;
        }
      } else if (Platform.isIOS) {
        final bool isJailbroken = (await RootCheckerPlus.isJailbreak()) ?? false;
        if (isJailbroken) {
          emit(AntiCheatDeviceUnsafe(reason: 'Thiết bị iOS đã bị jailbreak.'));
          return;
        }
      }
    } on PlatformException {}

    if (Platform.isAndroid) {
      await FlutterWindowManagerV2.addFlags(FlutterWindowManagerV2.FLAG_SECURE);
    }

    WidgetsBinding.instance.addObserver(this);
    emit(AntiCheatGuarding());
  }

  Future<void> stopGuarding() async {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isAndroid) {
      await FlutterWindowManagerV2.clearFlags(FlutterWindowManagerV2.FLAG_SECURE);
    }
    emit(AntiCheatIdle());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (state is! AntiCheatGuarding) return;

    if (lifecycleState == AppLifecycleState.paused) {
      _handleViolation(ViolationType.exitApp);
    }
  }

  void onSplitScreenDetected() {
    if (state is! AntiCheatGuarding) return;
    _handleViolation(ViolationType.splitScreen);
  }

  void _handleViolation(ViolationType type) {
    _violationCount++;

    final ViolationLog log = ViolationLog(
      userId: _userId,
      type: type,
      time: DateTime.now(),
      violationCount: _violationCount,
    );

    _violationLogs.add(log);
    _mockLogToConsole(log); // Lưu nhật ký vi phạm

    emit(AntiCheatViolationDetected(
      log: log,
      totalViolations: _violationCount,
    ));

    // Tự động khoá bài khi vi phạm lần 3
    if (_violationCount >= _maxViolations) {
      Future.delayed(const Duration(milliseconds: 800), () {
        emit(AntiCheatSubmitted());
      });
    }
  }

  void _mockLogToConsole(ViolationLog log) {
    print('[AntiCheat] Vi phạm lần ${log.violationCount}: ${log.type.label} lúc ${log.time}');
  }

  List<ViolationLog> get allLogs => List.unmodifiable(_violationLogs);
  int get violationCount => _violationCount;

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }
}