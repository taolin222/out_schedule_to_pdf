import 'package:flutter/material.dart';

class FixedDateDisplay extends StatelessWidget {
  final String dateText;

  const FixedDateDisplay({super.key, required this.dateText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('目标', style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              )),
            ),
            Text('考试日期', style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Text(dateText, style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280))),
            ],
          ),
        ),
      ],
    );
  }
}
