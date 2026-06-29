import 'package:flutter/material.dart';

import '../entities/answer.dart';
import '../entities/question.dart';
import '../entities/question_type.dart';

class AnswerItem extends StatefulWidget {
  final Question question;
  final Answer answer;

  const AnswerItem({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  State<AnswerItem> createState() => _AnswerItemState();
}

class _AnswerItemState extends State<AnswerItem> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(
      text: widget.answer.content,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool multiple =
        widget.question.type == QuestionType.multipleChoice;

    bool checked =
        widget.question.correctAnswerIds.contains(
      widget.answer.id,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [

          CircleAvatar(
            radius: 13,
            child: Text(widget.answer.id),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Đáp án ${widget.answer.id}",
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                widget.answer.content = value;
              },
            ),
          ),

          const SizedBox(width: 8),

          multiple
              ? Checkbox(
                  value: checked,
                  onChanged: (_) {

                    setState(() {

                      if (checked) {
                        widget.question.correctAnswerIds
                            .remove(widget.answer.id);
                      } else {
                        widget.question.correctAnswerIds
                            .add(widget.answer.id);
                      }

                    });

                  },
                )
              : Radio<String>(
                  value: widget.answer.id,
                  groupValue:
                      widget.question.correctAnswerIds
                              .isEmpty
                          ? null
                          : widget.question
                              .correctAnswerIds
                              .first,
                  onChanged: (value) {

                    if (value == null) return;

                    setState(() {

                      widget.question
                          .correctAnswerIds
                          .clear();

                      widget.question
                          .correctAnswerIds
                          .add(value);

                    });

                  },
                )
        ],
      ),
    );
  }
}