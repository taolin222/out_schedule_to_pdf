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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            minLines: 5,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}
