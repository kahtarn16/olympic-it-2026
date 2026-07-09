import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:olympic_it_project/core/config.dart';
import 'package:olympic_it_project/core/storage_token.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class ExamStompService {
  late StompClient _client;

  Future<void> connect({
    required int examId,
    required Function(Map<String, dynamic>) onMessage,
  }) async {
    final token = await StorageToken.instance.getAccessToken();

    final completer = Completer<void>();

    _client = StompClient(
      config: StompConfig(
        // Lấy WS_URL tập trung từ config.dart, không hardcode nữa
        url: WS_URL,

        stompConnectHeaders: {
          "Authorization": "Bearer $token",
          if (IS_USING_NGROK) "ngrok-skip-browser-warning": "true",
        },

        webSocketConnectHeaders: {
          if (IS_USING_NGROK) "ngrok-skip-browser-warning": "true",
        },

        reconnectDelay: const Duration(seconds: 5),

        onDebugMessage: (message) => debugPrint("[STOMP TRACE]: $message"),

        onConnect: (frame) {

          _client.subscribe(
            destination: '/topic/exam/$examId',
            callback: (frame) {
              if (frame.body == null) return;
              onMessage(jsonDecode(frame.body!));
            },
          );
          _client.subscribe(
            destination: '/topic/exam/$examId/anti-cheat',
            callback: (frame) {
              if (frame.body == null) return;
              final body = jsonDecode(frame.body!);
              onMessage({"type": "ANTI_CHEAT", "data": body});
            },
          );

          completer.complete();
        },

        onWebSocketError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onStompError: (frame) {
          debugPrint("${frame.body}");
        },
      ),
    );

    _client.activate();

    return completer.future;
  }

  void disconnect() {
    _client.deactivate();
  }
}