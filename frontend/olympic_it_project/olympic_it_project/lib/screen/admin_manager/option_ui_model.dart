import 'package:flutter/material.dart';

class OptionUIModel {
  final TextEditingController textController = TextEditingController();
  String? imageUrl;
  bool isUploading = false;
  void dispose() {
    textController.dispose();
  }

  void clearImage() {
    imageUrl = null;
  }
}