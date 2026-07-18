import 'package:flutter/material.dart';

class MultiLineTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;

  const MultiLineTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 5,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          ),
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      ],
    );
  }
}
