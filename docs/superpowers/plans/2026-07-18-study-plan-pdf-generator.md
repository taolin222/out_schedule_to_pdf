# 公考学习计划 PDF 生成器 — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an iOS Flutter app that generates a printable PDF study plan for Chinese civil service exam preparation, based on a Word template.

**Architecture:** Two-screen Flutter app (input form → PDF preview). The PDF is generated programmatically using the `pdf` Dart package, replicating the Word template's table layout with dynamic rows for user-entered sub-items. Simple local persistence via `shared_preferences` saves last-entered text values.

**Tech Stack:** Flutter 3.12+, `pdf: ^3.11.0`, `printing: ^5.13.0`, `shared_preferences: ^2.3.0`, Noto Sans SC font

## Global Constraints

- All user-facing text is Simplified Chinese
- PDF output must match the layout of `fixture/7-9月专项计划.docx` — 5-column table (任务, 完成, 做题时间, 复盘时间, 总用时) with vertical cell merges for category names
- All table cells: content horizontally and vertically centered
- Every table row has horizontal border lines
- Must run fully offline on iOS
- Noto Sans SC (Regular + Bold) bundled in `assets/fonts/`
- No data uploaded — 100% local
- Plan date selector max date = exam date

---

### Task 1: Set up dependencies, assets, and project scaffolding

**Files:**
- Modify: `pubspec.yaml`
- Create: `assets/fonts/.gitkeep` (placeholder — fonts added manually)
- Modify: `lib/main.dart`

- [ ] **Step 1: Add dependencies to pubspec.yaml**

Read current `pubspec.yaml` first, then update the `dependencies:` section:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  pdf: ^3.11.0
  printing: ^5.13.0
  shared_preferences: ^2.3.0
```

And add the fonts section under `flutter:`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/fonts/
  fonts:
    - family: NotoSansSC
      fonts:
        - asset: assets/fonts/NotoSansSC-Regular.ttf
        - asset: assets/fonts/NotoSansSC-Bold.ttf
          weight: 700
```

- [ ] **Step 2: Create directory structure**

```bash
mkdir -p lib/models lib/screens lib/services lib/widgets assets/fonts
touch assets/fonts/.gitkeep
```

- [ ] **Step 3: Create placeholder directories and verify**

```bash
ls -la lib/ assets/fonts/
```
Expected: all directories exist.

- [ ] **Step 4: Commit scaffolding**

```bash
git add pubspec.yaml assets/fonts/.gitkeep lib/
git commit -m "chore: add dependencies and project scaffolding"
```

---

### Task 2: Implement StudyPlan data model

**Files:**
- Create: `lib/models/study_plan.dart`

- [ ] **Step 1: Write the model class**

```dart
class StudyPlan {
  final DateTime examDate;
  final DateTime planDate;
  final String verbalItems;    // 换行分隔的子项目，如 "逻辑填空\n语句衔接"
  final String reasoningItems; // 换行分隔的子项目

  const StudyPlan({
    required this.examDate,
    required this.planDate,
    required this.verbalItems,
    required this.reasoningItems,
  });

  /// 星期几的中文名称
  String get weekdayChinese {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[planDate.weekday - 1];
  }

  /// 距考试天数
  int get daysUntilExam => examDate.difference(planDate).inDays;

  /// 言语子项目列表（按行拆分）
  List<String> get verbalItemList =>
      verbalItems.split('\n').where((s) => s.trim().isNotEmpty).toList();

  /// 判断推理子项目列表（按行拆分）
  List<String> get reasoningItemList =>
      reasoningItems.split('\n').where((s) => s.trim().isNotEmpty).toList();
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf && dart analyze lib/models/study_plan.dart
```
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/models/study_plan.dart
git commit -m "feat: add StudyPlan data model"
```

---

### Task 3: Implement PDF generator service

**Files:**
- Create: `lib/services/pdf_generator.dart`

**Interfaces:**
- Consumes: `StudyPlan` from `lib/models/study_plan.dart`
- Produces: `Future<Uint8List> generatePdf(StudyPlan plan)` — returns PDF bytes

**Layout notes (reverse-engineered from fixture/7-9月专项计划.docx):**
- Page: A4 portrait
- Title: "模块学习" — bold, 16pt, centered
- Info line: "2026年 M月 D日 星期X    学习时长：________ 距考试还有 N 天" — 10pt
- Table: 5 visual columns with widths proportional to:
  - 任务: 2.5
  - 完成: 1
  - 做题时间: 1
  - 复盘时间: 1
  - 总用时: 1
- Category names (言语, 判断推理, 申论, etc.) vertically merged and centered
- Every row has full horizontal borders
- Footer: "总结及心得：" row with full-width merge

- [ ] **Step 1: Create pdf_generator.dart with the full implementation**

```dart
import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/study_plan.dart';

class PdfGenerator {
  static const _pageWidth = PdfPageFormat.a4;
  static const _fontSize = 9.0;
  static const _headerFontSize = 14.0;
  static const _infoFontSize = 10.0;

  static Future<Uint8List> generatePdf(StudyPlan plan) async {
    final pdf = pw.Document();

    // Load font
    final fontData = await rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/NotoSansSC-Bold.ttf');
    final font = pw.Font.ttf(fontData);
    final fontBold = pw.Font.ttf(fontBoldData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginBottom: 20,
          marginTop: 20,
          marginLeft: 25,
          marginRight: 25,
        ),
        build: (context) => [
          _buildHeader(plan, font, fontBold),
          pw.SizedBox(height: 8),
          _buildTable(plan, font),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    StudyPlan plan,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Center(
          child: pw.Text(
            '模块学习',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: _headerFontSize,
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            '${plan.planDate.year}年 ${plan.planDate.month}月 ${plan.planDate.day}日 ${plan.weekdayChinese}'
            '    学习时长：________ 距考试还有 ${plan.daysUntilExam} 天',
            style: pw.TextStyle(font: font, fontSize: _infoFontSize),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTable(StudyPlan plan, pw.Font font) {
    final verbalItems = plan.verbalItemList;
    final reasoningItems = plan.reasoningItemList;

    // Build table rows
    final rows = <pw.TableRow>[];

    // Header row
    rows.add(_headerRow(font));

    // 言语 section (dynamic rows based on verbalItems)
    if (verbalItems.isEmpty) {
      rows.add(_categoryRow('言语', font, rowSpan: 1));
    } else {
      rows.addAll(_dynamicSectionRows('言语', verbalItems, font));
    }

    // 判断推理 section (dynamic rows based on reasoningItems)
    if (reasoningItems.isEmpty) {
      rows.add(_categoryRow('判断推理', font, rowSpan: 1));
    } else {
      rows.addAll(_dynamicSectionRows('判断推理', reasoningItems, font));
    }

    // 数量 section (fixed, 2 rows)
    rows.addAll(_fixedSectionRows('数量', 2, font));

    // 资料分析 section (fixed, 2 rows)
    rows.addAll(_fixedSectionRows('资料分析', 2, font));

    // 政治理论 section (fixed, 1 row)
    rows.addAll(_fixedSectionRows('政治理论', 1, font));

    // 常识 section (fixed, 1 row)
    rows.addAll(_fixedSectionRows('常识', 1, font));

    // 申论 section (fixed, with sub-items)
    rows.addAll(_shenlunRows(font));

    // 总结及心得 row
    rows.add(_summaryRow(font));

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.black,
        width: 0.5,
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      children: rows,
    );
  }

  static pw.TableRow _headerRow(pw.Font font) {
    return pw.TableRow(
      children: [
        _cell('任务', font, isHeader: true),
        _cell('完成', font, isHeader: true),
        _cell('做题时间', font, isHeader: true),
        _cell('复盘时间', font, isHeader: true),
        _cell('总用时', font, isHeader: true),
      ],
    );
  }

  static pw.Widget _cell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    int? rowSpan,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: _fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _emptyCell(pw.Font font) {
    return _cell('', font);
  }

  /// 动态模块行：分类名称跨行合并 + 每行一个子项
  static List<pw.TableRow> _dynamicSectionRows(
    String category,
    List<String> items,
    pw.Font font,
  ) {
    final rows = <pw.TableRow>[];
    for (int i = 0; i < items.length; i++) {
      final isFirst = i == 0;
      rows.add(pw.TableRow(
        children: [
          if (isFirst)
            _cell(category, font, rowSpan: items.length)
          else
            _emptyCell(font),
          _cell(items[i], font),
          _emptyCell(font),
          _emptyCell(font),
          _emptyCell(font),
        ],
      ));
    }
    return rows;
  }

  /// 固定模块行：分类名称跨行合并，剩余单元格留空
  static List<pw.TableRow> _fixedSectionRows(
    String category,
    int rowCount,
    pw.Font font,
  ) {
    // Split 资料分析 into 资料/分析 across 2 rows if needed
    // 政治理论 stays as one
    if (category == '资料分析' && rowCount == 2) {
      return [
        pw.TableRow(children: [
          _cell('资料', font),
          _emptyCell(font),
          _emptyCell(font),
          _emptyCell(font),
          _emptyCell(font),
        ]),
        pw.TableRow(children: [
          _cell('分析', font),
          _emptyCell(font),
          _emptyCell(font),
          _emptyCell(font),
          _emptyCell(font),
        ]),
      ];
    }

    if (category == '政治理论' && rowCount == 1) {
      return [
        pw.TableRow(children: [
          _cell('政治理论', font),
          _emptyCell(font),
          _emptyCell(font),
          _emptyCell(font),
          _emptyCell(font),
        ]),
      ];
    }

    if (category == '常识' && rowCount == 1) {
      return [
        pw.TableRow(children: [
          _cell('常识', font),
          _emptyCell(font),
          _emptyCell(font),
          _emptyCell(font),
          _emptyCell(font),
        ]),
      ];
    }

    if (category == '数量' && rowCount == 2) {
      return [
        pw.TableRow(children: [
          _cell('数量', font),
          _emptyCell(font),
          _emptyCell(font),
          _emptyCell(font),
          _emptyCell(font),
        ]),
        pw.TableRow(children: [
          _emptyCell(font),
          _emptyCell(font),
          _emptyCell(font),
          _emptyCell(font),
          _emptyCell(font),
        ]),
      ];
    }

    // Fallback
    return List.generate(rowCount, (i) {
      return pw.TableRow(children: [
        i == 0 ? _cell(category, font) : _emptyCell(font),
        _emptyCell(font),
        _emptyCell(font),
        _emptyCell(font),
        _emptyCell(font),
      ]);
    });
  }

  /// 申论固定行（小题→概括题/分析题/贯彻执行，大作文）
  static List<pw.TableRow> _shenlunRows(pw.Font font) {
    return [
      // 申论 → 小题
      pw.TableRow(children: [
        _cell('申论', font),
        _cell('小题', font),
        _emptyCell(font),
        _emptyCell(font),
        _emptyCell(font),
      ]),
      // 概括题
      pw.TableRow(children: [
        _emptyCell(font),
        _emptyCell(font),
        _cell('概括题', font),
        _emptyCell(font),
        _emptyCell(font),
      ]),
      // 分析题
      pw.TableRow(children: [
        _emptyCell(font),
        _emptyCell(font),
        _cell('分析题', font),
        _emptyCell(font),
        _emptyCell(font),
      ]),
      // 贯彻执行
      pw.TableRow(children: [
        _emptyCell(font),
        _emptyCell(font),
        _cell('贯彻执行', font),
        _emptyCell(font),
        _emptyCell(font),
      ]),
      // 大作文
      pw.TableRow(children: [
        _emptyCell(font),
        _cell('大作文', font),
        _emptyCell(font),
        _emptyCell(font),
        _emptyCell(font),
      ]),
    ];
  }

  static pw.TableRow _summaryRow(pw.Font font) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            '总结及心得：',
            style: pw.TextStyle(font: font, fontSize: _fontSize),
          ),
        ),
        _emptyCell(font),
        _emptyCell(font),
        _emptyCell(font),
        _emptyCell(font),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf && dart analyze lib/services/pdf_generator.dart
```
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/services/pdf_generator.dart
git commit -m "feat: add PDF generator service"
```

---

### Task 4: Implement form widgets

**Files:**
- Create: `lib/widgets/date_picker_field.dart`
- Create: `lib/widgets/multi_line_text_field.dart`

- [ ] **Step 1: Create date_picker_field.dart**

```dart
import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime> onDateSelected;

  const DatePickerField({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickDate(context),
              icon: const Icon(Icons.calendar_today),
              label: Text(
                selectedDate != null
                    ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                    : '选择日期',
              ),
            ),
          ),
        ],
      ),
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
    if (picked != null) {
      onDateSelected(picked);
    }
  }
}
```

- [ ] **Step 2: Create multi_line_text_field.dart**

```dart
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
```

- [ ] **Step 3: Verify compilation**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf && dart analyze lib/widgets/
```
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/
git commit -m "feat: add date picker and multi-line text field widgets"
```

---

### Task 5: Implement persistence service

**Files:**
- Create: `lib/services/persistence_service.dart`

**Interfaces:**
- Produces: `Future<String?> getLastVerbalItems()`, `Future<String?> getLastReasoningItems()`, `Future<void> saveVerbalItems(String)`, `Future<void> saveReasoningItems(String)`

- [ ] **Step 1: Create persistence_service.dart**

```dart
import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static const _verbalKey = 'last_verbal_items';
  static const _reasoningKey = 'last_reasoning_items';

  static Future<String?> getLastVerbalItems() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_verbalKey);
  }

  static Future<String?> getLastReasoningItems() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_reasoningKey);
  }

  static Future<void> saveVerbalItems(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_verbalKey, value);
  }

  static Future<void> saveReasoningItems(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reasoningKey, value);
  }
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf && dart analyze lib/services/persistence_service.dart
```
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/services/persistence_service.dart
git commit -m "feat: add persistence service for saving last-entered items"
```

---

### Task 6: Implement input screen (首页)

**Files:**
- Create: `lib/screens/input_screen.dart`

**Interfaces:**
- Consumes: `DatePickerField`, `MultiLineTextField`, `PersistenceService`, `PdfGenerator`
- Produces: navigates to `PreviewScreen` with `Uint8List` PDF bytes

- [ ] **Step 1: Create input_screen.dart**

```dart
import 'dart:typed_data';
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

    final pdfBytes = await PdfGenerator.generatePdf(plan);

    if (!mounted) return;
    setState(() => _isGenerating = false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewScreen(pdfBytes: pdfBytes),
      ),
    );
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
```

- [ ] **Step 2: Verify compilation**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf && dart analyze lib/screens/input_screen.dart
```
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/input_screen.dart
git commit -m "feat: add input screen with form"
```

---

### Task 7: Implement preview screen (预览页)

**Files:**
- Create: `lib/screens/preview_screen.dart`

**Interfaces:**
- Consumes: `Uint8List` pdf bytes
- Produces: PDF preview via `printing` package, share/print actions

- [ ] **Step 1: Create preview_screen.dart**

```dart
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;

  const PreviewScreen({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF预览'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '保存',
            onPressed: () => _savePdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '分享',
            onPressed: () => _sharePdf(context),
          ),
        ],
      ),
      body: PdfPreview(
        pdfProvider: () => _pdfData(),
        initialPageFormat: PdfPageFormat.a4,
        canChangePageFormat: false,
        canZoom: true,
      ),
    );
  }

  Future<Uint8List> _pdfData() async => pdfBytes;

  Future<void> _savePdf(BuildContext context) async {
    await Printing.savePdf(
      doc: _pdfData,
      filename: 'module_study_plan.pdf',
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'module_study_plan.pdf',
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf && dart analyze lib/screens/preview_screen.dart
```
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/preview_screen.dart
git commit -m "feat: add PDF preview screen with save and share"
```

---

### Task 8: Wire up main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Replace main.dart content**

```dart
import 'package:flutter/material.dart';
import 'screens/input_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '模块学习计划生成器',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const InputScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 2: Verify full project analyzes cleanly**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf && flutter analyze
```
Expected: No issues found. (Some info-level hints about unused imports are OK.)

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: wire up app entry point"
```

---

### Task 9: Download Noto Sans SC fonts and build test

**Files:**
- Add: `assets/fonts/NotoSansSC-Regular.ttf`
- Add: `assets/fonts/NotoSansSC-Bold.ttf`

- [ ] **Step 1: Download fonts from Google Fonts**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf/assets/fonts
# Download Noto Sans SC from Google Fonts
curl -L "https://github.com/googlefonts/noto-cjk/releases/download/Sans2.004/03_NotoSansCJKsc.zip" -o noto.zip
unzip -o noto.zip -d noto_temp
# Find and copy the TTF files
find noto_temp -name "NotoSansSC-Regular.otf" -exec cp {} ./NotoSansSC-Regular.otf \;
find noto_temp -name "NotoSansSC-Bold.otf" -exec cp {} ./NotoSansSC-Bold.otf \;
# Clean up
rm -rf noto.zip noto_temp
```

Note: The actual URL may differ. If the download fails, manually download from https://fonts.google.com/noto/specimen/Noto+Sans+SC and place the files in `assets/fonts/`.

- [ ] **Step 2: Verify font files exist**

```bash
ls -la /Users/chengfan/project/out_schedule_to_pdf/assets/fonts/
```
Expected: `NotoSansSC-Regular.ttf` (or .otf) and `NotoSansSC-Bold.ttf` (or .otf) present.

If the files are .otf, update the pubspec.yaml font declaration:

```yaml
fonts:
  - family: NotoSansSC
    fonts:
      - asset: assets/fonts/NotoSansSC-Regular.otf
      - asset: assets/fonts/NotoSansSC-Bold.otf
        weight: 700
```

- [ ] **Step 3: Run flutter build to verify everything compiles**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf && flutter build ios --no-codesign --simulator
```
Expected: BUILD SUCCESSFUL.

- [ ] **Step 4: Commit font assets**

```bash
git add assets/fonts/ pubspec.yaml
git commit -m "feat: add Noto Sans SC font files"
```

---

### Task 10: Update widget tests

**Files:**
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Replace test with meaningful smoke test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:out_schedule_to_pdf/main.dart';

void main() {
  testWidgets('App renders input form', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify the app title is shown
    expect(find.text('模块学习计划生成器'), findsOneWidget);

    // Verify date picker fields are present
    expect(find.text('考试日期'), findsOneWidget);
    expect(find.text('计划日期'), findsOneWidget);

    // Verify multi-line text fields are present
    expect(find.text('言语'), findsOneWidget);
    expect(find.text('判断推理'), findsOneWidget);

    // Verify generate button
    expect(find.text('生成预览'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf && flutter test
```
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/widget_test.dart
git commit -m "test: update smoke test for input form"
```

---

## Scope Verification (against design spec)

| Spec Requirement | Implemented In |
|---|---|
| Input form: exam date picker | Task 6 (InputScreen) |
| Input form: plan date picker | Task 6 (InputScreen) |
| Plan date ≤ exam date constraint | Task 6 (DatePickerField lastDate) |
| Multi-line text for 言语 | Task 6 (MultiLineTextField) |
| Multi-line text for 判断推理 | Task 6 (MultiLineTextField) |
| Default values for text fields | Task 6 (_loadSavedData) |
| Persist last entered values | Task 5 (PersistenceService) |
| PDF with template layout | Task 3 (PdfGenerator) |
| PDF preview | Task 7 (PreviewScreen) |
| PDF save/share | Task 7 (savePdf / sharePdf) |
| Noto Sans SC font | Task 9 |
| Empty sub-items → no extra rows | Task 3 (verbalItemList filtering) |
| 申论 fixed structure | Task 3 (_shenlunRows) |
| 言语/判断推理 dynamic rows | Task 3 (_dynamicSectionRows) |
| All cells centered, borders | Task 3 (pw.Table + Alignment.center) |
| Offline, no data upload | All code is local |
