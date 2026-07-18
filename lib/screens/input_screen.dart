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
        MaterialPageRoute(builder: (_) => PreviewScreen(pdfBytes: pdfBytes)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Header
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('学习计划', style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
                ],
              ),
              const SizedBox(height: 4),
              Text('填写信息后生成可打印的每日学习计划表',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  )),
              const SizedBox(height: 24),

              // 日期卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(theme, Icons.date_range_rounded, '日期设置'),
                      const SizedBox(height: 16),
                      DatePickerField(
                        label: '考试日期',
                        iconText: '目标',
                        selectedDate: _examDate,
                        onDateSelected: (date) {
                          setState(() {
                            _examDate = date;
                            if (_planDate != null && _planDate!.isAfter(date)) {
                              _planDate = null;
                            }
                          });
                        },
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                      ),
                      const SizedBox(height: 20),
                      DatePickerField(
                        label: '计划日期',
                        iconText: '计划',
                        selectedDate: _planDate,
                        onDateSelected: (date) => setState(() => _planDate = date),
                        firstDate: DateTime(2020),
                        lastDate: _examDate,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 内容卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(theme, Icons.menu_book_rounded, '学习内容'),
                      const SizedBox(height: 16),
                      MultiLineTextField(
                        label: '言语',
                        controller: _verbalController,
                        hintText: '每行输入一个子项目',
                      ),
                      const SizedBox(height: 20),
                      MultiLineTextField(
                        label: '判断推理',
                        controller: _reasoningController,
                        hintText: '每行输入一个子项目',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 生成按钮
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isFormValid && !_isGenerating ? _generatePdf : null,
                  child: _isGenerating
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, size: 20),
                            const SizedBox(width: 8),
                            const Text('生成预览'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _sectionHeader(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        )),
      ],
    );
  }
}
