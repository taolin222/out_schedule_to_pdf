import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final String? iconText;
  final DateTime? selectedDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime> onDateSelected;

  const DatePickerField({
    super.key,
    required this.label,
    this.iconText,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
  });

  String get _displayText {
    if (selectedDate == null) return '请选择日期';
    final d = selectedDate!;
    return '${d.year}年 ${d.month}月 ${d.day}日';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (iconText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(iconText!, style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                )),
              ),
            Text(label, style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickDate(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _displayText,
                    style: TextStyle(
                      fontSize: 15,
                      color: selectedDate != null
                          ? theme.colorScheme.onSurface
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: const Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
    );
    if (picked != null && context.mounted) {
      onDateSelected(picked);
    }
  }
}
