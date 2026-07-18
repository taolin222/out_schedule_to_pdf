import 'package:flutter/material.dart';
import '../models/study_plan.dart';
import '../services/pdf_generator.dart';
import '../services/persistence_service.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/multi_line_text_field.dart';
import 'preview_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  DateTime? _examDate;
  DateTime? _planDate;
  final _verbalController = TextEditingController();
  final _reasoningController = TextEditingController();
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final verbal = await PersistenceService.getLastVerbalItems();
    final reasoning = await PersistenceService.getLastReasoningItems();
    if (!mounted) return;
    setState(() {
      _verbalController.text = verbal ?? '逻辑填空\n语句衔接\n片段阅读';
      _reasoningController.text = reasoning ?? '类比推理\n图推\n定义判断\n逻辑判断';
    });
  }

  @override
  void dispose() {
    _verbalController.dispose();
    _reasoningController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _examDate != null && _planDate != null &&
      _verbalController.text.trim().isNotEmpty &&
      _reasoningController.text.trim().isNotEmpty;

  Future<void> _generatePdf() async {
    if (!_isFormValid) return;

    setState(() => _isGenerating = true);

    // Save current input
    await PersistenceService.saveVerbalItems(_verbalController.text);
    await PersistenceService.saveReasoningItems(_reasoningController.text);

    final plan = StudyPlan(
      examDate: _examDate!,
      planDate: _planDate!,
      verbalItems: _verbalController.text,
      reasoningItems: _reasoningController.text,
    );

    try {
      final pdfBytes = await PdfGenerator.generatePdf(plan);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PreviewScreen(pdfBytes: pdfBytes),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成 PDF 失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模块学习计划生成器'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DatePickerField(
              label: '考试日期',
              selectedDate: _examDate,
              onDateSelected: (date) {
                setState(() {
                  _examDate = date;
                  // If plan date is after exam date, reset it
                  if (_planDate != null && _planDate!.isAfter(date)) {
                    _planDate = null;
                  }
                });
              },
              firstDate: DateTime.now(),
              lastDate: DateTime(2035),
            ),
            DatePickerField(
              label: '计划日期',
              selectedDate: _planDate,
              onDateSelected: (date) => setState(() => _planDate = date),
              firstDate: DateTime(2020),
              lastDate: _examDate, // 限制 ≤ 考试日期
            ),
            const SizedBox(height: 16),
            const Divider(),
            MultiLineTextField(
              label: '言语',
              controller: _verbalController,
              hintText: '每行一个子项目',
            ),
            const SizedBox(height: 8),
            MultiLineTextField(
              label: '判断推理',
              controller: _reasoningController,
              hintText: '每行一个子项目',
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isFormValid && !_isGenerating ? _generatePdf : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('生成预览', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
