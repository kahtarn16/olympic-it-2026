import 'package:flutter/material.dart';

class ErrorSnackbar {
  static void showError(BuildContext context, dynamic error, {String defaultMessage = 'Đã xảy ra lỗi'}) {
    final message = _extractMessage(error) ?? defaultMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  static String? _extractMessage(dynamic error) {
    if (error == null) return null;
    if (error is String) return error;
    try {
      final s = error.toString();
      return s.replaceAll('Exception: ', '');
    } catch (_) {
      return error.toString();
    }
  }
}
