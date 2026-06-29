import 'package:flutter/material.dart';

class StepItem extends StatelessWidget {
  final String title;
  final int index;
  final int currentStep;

  const StepItem({
    super.key,
    required this.title,
    required this.index,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    bool done = index < currentStep;
    bool active = index == currentStep;

    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: done || active ? Colors.blue : Colors.grey,
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  "$index",
                  style: const TextStyle(color: Colors.white),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 11),
        )
      ],
    );
  }
}