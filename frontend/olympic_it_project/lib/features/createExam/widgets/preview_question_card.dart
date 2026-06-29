import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../entities/question.dart';
import '../entities/question_type.dart';
import '../entities/difficulty.dart';

class PreviewQuestionCard extends StatefulWidget {
  final Question question;

  const PreviewQuestionCard({
    super.key,
    required this.question,
  });

  @override
  State<PreviewQuestionCard> createState() =>
      _PreviewQuestionCardState();
}

class _PreviewQuestionCardState
    extends State<PreviewQuestionCard> {

  Set<String> selectedAnswers = {};
  TextEditingController essayController = TextEditingController();

  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();

    if (widget.question.videoFile != null) {
      _videoController =
          VideoPlayerController.file(
            widget.question.videoFile!,
          )
            ..initialize().then((_) {
              if (mounted) setState(() {});
            });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    essayController.dispose();
    super.dispose();
  }

  String getQuestionType() {
    switch (widget.question.type) {
      case QuestionType.singleChoice:
        return "TRẮC NGHIỆM";

      case QuestionType.multipleChoice:
        return "TRẮC NGHIỆM";

      case QuestionType.essay:
        return "TỰ LUẬN";
    }
  }

  String getDifficulty() {
    switch (widget.question.difficulty) {
      case Difficulty.easy:
        return "Dễ";

      case Difficulty.medium:
        return "Trung bình";

      case Difficulty.hard:
        return "Khó";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Header
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [

                Chip(
                  label: Text(
                    "CÂU ${widget.question.order}",
                  ),
                ),

                Chip(
                  label: Text(getQuestionType()),
                ),

                Chip(
                  label: Text(
                    "Độ khó: ${getDifficulty()}",
                  ),
                ),
              ],
            ),      

            const SizedBox(height: 5),

            Text(
              widget.question.content,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            /// Ảnh
            if (widget.question.imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  widget.question.imageFile!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),

            if (widget.question.imageFile != null)
              const SizedBox(height: 12),

            /// Video
            if (_videoController != null &&
                _videoController!.value.isInitialized)
              AspectRatio(
                aspectRatio:
                    _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),

            if (_videoController != null)
              Row(
                children: [

                  IconButton(
                    icon: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () {
                      setState(() {

                        if (_videoController!
                            .value
                            .isPlaying) {
                          _videoController!.pause();
                        } else {
                          _videoController!.play();
                        }

                      });
                    },
                  ),
                ],
              ),

            const SizedBox(height: 15),

            /// Đáp án
            /// Đáp án (chỉ hiển thị cho trắc nghiệm)
          if (widget.question.type != QuestionType.essay)
            ...widget.question.answers.map((answer) {
              bool correct =
                  widget.question.correctAnswerIds.contains(answer.id);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade400,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey,
                      child: Text(
                        answer.id,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(answer.content),
                    ),

                    if (widget.question.type == QuestionType.singleChoice)
                      Radio<String>(
                        value: answer.id,
                        groupValue:
                            selectedAnswers.isNotEmpty ? selectedAnswers.first : null,
                        onChanged: (value) {
                          setState(() {
                            selectedAnswers = {value!};
                          });
                        },
                      ),

                    if (widget.question.type == QuestionType.multipleChoice)
                      Checkbox(
                        value: selectedAnswers.contains(answer.id),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedAnswers.add(answer.id);
                            } else {
                              selectedAnswers.remove(answer.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
              );
            }).toList(),

            if (widget.question.type == QuestionType.essay)
              TextField(
                controller: essayController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "Nhập câu trả lời tự luận...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}