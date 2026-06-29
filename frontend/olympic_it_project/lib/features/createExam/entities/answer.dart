import 'package:flutter/material.dart';

class Answer {
  String id;
  String content;

  late TextEditingController controller;

  Answer({
    required this.id,
    required this.content,
  }) {
    controller = TextEditingController(text: content);
  }

  void dispose() {
    controller.dispose();
  }
}