# 模块排序功能 — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to reorder the 7 study plan modules in PDF output via a drag-to-reorder settings page, persisted in SharedPreferences.

**Architecture:** ModuleKeys constants → PersistenceService stores comma-separated order → ReorderScreen (ReorderableListView) edits order → PdfGenerator reads order and renders modules in sequence.

**Tech Stack:** Flutter, `shared_preferences`, `ReorderableListView`

## Global Constraints

- Summary (总结及心得) is always last, not in the reorderable list
- Default order: 言语理解, 判断推理, 数量, 资料分析, 政治常识, 时政, 申论
- Order stored as comma-separated string in SharedPreferences key `module_order`
- No persistence = default order used
- All existing functionality must remain unchanged

---

### Task 1: Create ModuleKeys constants and PersistenceService extension

**Files:**
- Create: `lib/models/module_keys.dart`
- Modify: `lib/services/persistence_service.dart`

**Interfaces:**
- Produces: `ModuleKeys` class with 7 static const strings + `defaultOrder`
- Produces: `PersistenceService.getModuleOrder()`, `PersistenceService.saveModuleOrder(String)`

- [ ] **Step 1: Create lib/models/module_keys.dart**

```dart
class ModuleKeys {
  static const verbal = '言语理解';
  static const reasoning = '判断推理';
  static const quantity = '数量';
  static const dataAnalysis = '资料分析';
  static const politics = '政治常识';
  static const currentAffairs = '时政';
  static const shenlun = '申论';

  static const defaultOrder = [
    verbal, reasoning, quantity, dataAnalysis,
    politics, currentAffairs, shenlun,
  ];

  /// Parse stored comma-separated string into List<String>.
  /// Returns defaultOrder if input is null or empty.
  static List<String> fromStored(String? stored) {
    if (stored == null || stored.trim().isEmpty) return defaultOrder;
    final parts = stored.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    // Validate: only known keys, no duplicates, and only these 7 keys
    if (parts.length != defaultOrder.length) return defaultOrder;
    if (!parts.every((p) => defaultOrder.contains(p))) return defaultOrder;
    return parts;
  }

  /// Serialize order list to comma-separated string for storage.
  static String toStored(List<String> order) => order.join(',');
}
```

- [ ] **Step 2: Extend PersistenceService with module order methods**

```dart
class PersistenceService {
  static const _orderKey = 'module_order';

  // ... existing getLastVerbalItems, saveVerbalItems, etc.

  static Future<String?> getModuleOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_orderKey);
  }

  static Future<void> saveModuleOrder(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orderKey, value);
  }
}
```

- [ ] **Step 3: Verify compilation**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf && dart analyze lib/models/module_keys.dart && dart analyze lib/services/persistence_service.dart
```
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/models/module_keys.dart lib/services/persistence_service.dart
git commit -m "feat: add ModuleKeys model and PersistenceService module order methods"
```

---

### Task 2: Create ReorderScreen

**Files:**
- Create: `lib/screens/reorder_screen.dart`

**Interfaces:**
- Consumes: `ModuleKeys`, `PersistenceService`
- Produces: Navigates back after saving, caller reloads order on return

- [ ] **Step 1: Create reorder_screen.dart**

```dart
import 'package:flutter/material.dart';
import '../models/module_keys.dart';
import '../services/persistence_service.dart';

class ReorderScreen extends StatefulWidget {
  const ReorderScreen({super.key});

  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  List<String> _modules = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final stored = await PersistenceService.getModuleOrder();
    if (!mounted) return;
    setState(() {
      _modules = ModuleKeys.fromStored(stored);
      _loaded = true;
    });
  }

  Future<void> _saveOrder() async {
    await PersistenceService.saveModuleOrder(ModuleKeys.toStored(_modules));
    if (!mounted) return;
    Navigator.of(context).pop(true); // true = order changed
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('模块排序'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: _loaded
          ? ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _modules.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _modules.removeAt(oldIndex);
                  _modules.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                return Card(
                  key: ValueKey(_modules[index]),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.drag_handle, color: theme.colorScheme.primary),
                    title: Text(_modules[index], style: const TextStyle(fontSize: 16)),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_indicator),
                    ),
                  ),
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveOrder,
        icon: const Icon(Icons.save),
        label: const Text('保存'),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf && dart analyze lib/screens/reorder_screen.dart
```
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/reorder_screen.dart
git commit -m "feat: add reorder screen for module ordering"
```

---

### Task 3: Add settings button to InputScreen

**Files:**
- Modify: `lib/screens/input_screen.dart`

**Interfaces:**
- Consumes: `ReorderScreen`, `ModuleKeys`, `PersistenceService`
- Produces: Navigates to ReorderScreen on gear icon tap; loads order before PDF generation

- [ ] **Step 1: Add import for module_keys and reorder_screen**

```dart
import '../models/module_keys.dart';
import 'reorder_screen.dart';
```

- [ ] **Step 2: Add _moduleOrder state and load it in initState**

Add instance variable:
```dart
List<String> _moduleOrder = ModuleKeys.defaultOrder;
```

Load in `initState`:
```dart
_loadModuleOrder();
```

Add method:
```dart
Future<void> _loadModuleOrder() async {
  final stored = await PersistenceService.getModuleOrder();
  if (!mounted) return;
  setState(() {
    _moduleOrder = ModuleKeys.fromStored(stored);
  });
}
```

- [ ] **Step 3: Add gear icon to AppBar**

The InputScreen doesn't have an AppBar currently (it uses a custom header). Add a settings IconButton at the top-right of the body. In the build method, after the header Row, add:

```dart
// Add this after the header Row and subtitle Text, before the Card:
Align(
  alignment: Alignment.centerRight,
  child: IconButton(
    icon: Icon(Icons.settings_outlined, color: theme.colorScheme.primary),
    tooltip: '模块排序',
    onPressed: () async {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const ReorderScreen()),
      );
      if (changed == true && mounted) {
        _loadModuleOrder();
      }
    },
  ),
),
```

- [ ] **Step 4: Pass _moduleOrder to PdfGenerator.generatePdf**

Modify the `_generatePdf` call to use the new API. The PdfGenerator.generatePdf will need to accept the order (updated in Task 4).

```dart
final pdfBytes = await PdfGenerator.generatePdf(plan, moduleOrder: _moduleOrder);
```

- [ ] **Step 5: Verify compilation**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf && flutter analyze lib/screens/input_screen.dart
```
Expected: No issues found (some errors expected until Task 4 is done).

- [ ] **Step 6: Commit**

```bash
git add lib/screens/input_screen.dart
git commit -m "feat: add settings button and module order loading to input screen"
```

---

### Task 4: Refactor pdf_generator.dart to support module ordering

**Files:**
- Modify: `lib/services/pdf_generator.dart`

**Interfaces:**
- Consumes: `ModuleKeys` model
- Produces: `static Future<Uint8List> generatePdf(StudyPlan plan, {List<String>? moduleOrder})` — new optional param
- Extracted render functions: `_renderVerbal`, `_renderReasoning`, `_renderQuantity`, `_renderDataAnalysis`, `_renderPolitics`, `_renderCurrentAffairs`, `_renderShenlun` — all take `(List<pw.TableRow> rows, StudyPlan plan, pw.Font font, double rh)`

- [ ] **Step 1: Add import for ModuleKeys**

```dart
import '../models/module_keys.dart';
```

- [ ] **Step 2: Add moduleOrder param to generatePdf**

Change signature:
```dart
static Future<Uint8List> generatePdf(StudyPlan plan, {List<String>? moduleOrder}) async {
```

Pass it to `_buildTable`:
```dart
_buildTable(plan, font, moduleOrder: moduleOrder),
```

- [ ] **Step 3: Extract each module into its own static function**

Each function appends rows to the `rows` list. Here are the extracted functions:

```dart
// ─── 模块渲染函数（可排序） ──────────────────────────────────

static void _renderVerbal(List<pw.TableRow> rows, StudyPlan plan, pw.Font font, double rh) {
  final vItems = plan.verbalItemList;
  for (int i = 0; i < vItems.length; i++) {
    final catTxt = vItems.length > 1 ? _catChar('言语', i) : (i == 0 ? '言语' : '');
    rows.add(_makeRow(_ci8(catTxt, vItems[i]), font,
        height: rh, mergeCol0: i < vItems.length - 1, leftAlignCol: 1));
  }
}

static void _renderReasoning(List<pw.TableRow> rows, StudyPlan plan, pw.Font font, double rh) {
  final rItems = plan.reasoningItemList;
  for (int i = 0; i < rItems.length; i++) {
    rows.add(_makeRow(_ci8(_cat2Line('判断推理', rItems.length, i), rItems[i]), font,
        height: rh, mergeCol0: i < rItems.length - 1, leftAlignCol: 1));
  }
}

static void _renderQuantity(List<pw.TableRow> rows, StudyPlan plan, pw.Font font, double rh) {
  rows.add(_makeRow(_c8(_catChar('数量', 0)), font, height: 26, mergeCol0: true));
  rows.add(_makeRow(_c8(_catChar('数量', 1)), font, height: 26));
}

static void _renderDataAnalysis(List<pw.TableRow> rows, StudyPlan plan, pw.Font font, double rh) {
  rows.add(_makeRow(_c8(_catChar('资料分析', 0)), font, height: 26, mergeCol0: true));
  rows.add(_makeRow(_c8(_catChar('资料分析', 1)), font, height: 26));
}

static void _renderPolitics(List<pw.TableRow> rows, StudyPlan plan, pw.Font font, double rh) {
  // 政治常识 custom row
  rows.add(pw.TableRow(children: [
    pw.Container(width: double.infinity, height: rh + 6,
      decoration: const pw.BoxDecoration(border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
        left: pw.BorderSide(color: PdfColors.black, width: 0.5),
        right: pw.BorderSide(color: PdfColors.black, width: 0.5),
      )),
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6),
      child: pw.Text('政治常识', style: pw.TextStyle(font: font, fontSize: 11, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center)),
    pw.Container(width: double.infinity, height: rh + 6,
      decoration: const pw.BoxDecoration(border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.black, width: 0.5))),
      child: pw.SizedBox.shrink()),
    pw.Container(width: double.infinity, height: rh + 6,
      decoration: const pw.BoxDecoration(border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.black, width: 0.5))),
      child: pw.SizedBox.shrink()),
    pw.Container(width: double.infinity, height: rh + 6,
      decoration: const pw.BoxDecoration(border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.black, width: 0.5))),
      child: pw.SizedBox.shrink()),
    _borderedCell('', font, height: rh + 6),
    _borderedCell('', font, height: rh + 6),
    _borderedCell('', font, height: rh + 6),
    _borderedCell('', font, height: rh + 6),
  ]));
}

static void _renderCurrentAffairs(List<pw.TableRow> rows, StudyPlan plan, pw.Font font, double rh) {
  rows.add(_makeRow(_c8('时政'), font, height: rh));
}

static void _renderShenlun(List<pw.TableRow> rows, StudyPlan plan, pw.Font font, double rh) {
  rows.add(_makeRow(['', '小题', '概括题', '', '', '', '', ''], font,
      height: rh, mergeCol1Right: false, mergeCol0: true, mergeCol1: true, leftAlignCol: 2));
  rows.add(_makeRow(['申论', '', '分析题', '', '', '', '', ''], font,
      height: rh, mergeCol1Right: false, mergeCol0: true, mergeCol1: true, leftAlignCol: 2));
  rows.add(_makeRow(['', '', '贯彻执行', '', '', '', '', ''], font,
      height: rh, mergeCol1Right: false, mergeCol0: true, leftAlignCol: 2));
  rows.add(_makeRow(['', '大作文', '', '', '', '', '', ''], font,
      height: rh, leftAlignCol: 1));
}
```

- [ ] **Step 4: Replace _buildTable body with order-driven rendering**

Replace the entire body of `_buildTable` (from `final rows = <pw.TableRow>[];` to the return) with:

```dart
static pw.Widget _buildTable(StudyPlan plan, pw.Font font, {List<String>? moduleOrder}) {
  final rows = <pw.TableRow>[];
  const rh = 32.0;
  final order = moduleOrder ?? ModuleKeys.defaultOrder;

  // 表头（始终在最前）
  rows.add(pw.TableRow(children: [
    _borderedCell('', font, height: rh, topBorder: true, noRightBorder: true),
    _borderedCell('', font, height: rh, topBorder: true, noRightBorder: true, noLeftBorder: true),
    _borderedCell('任务', font, height: rh, topBorder: true, noRightBorder: true, noLeftBorder: true),
    _borderedCell('', font, height: rh, topBorder: true, noLeftBorder: true),
    _borderedCell('完成', font, height: rh, topBorder: true),
    _borderedCell('做题时间', font, height: rh, topBorder: true),
    _borderedCell('复盘时间', font, height: rh, topBorder: true),
    _borderedCell('总用时', font, height: rh, topBorder: true),
  ]));

  // 按用户设定的顺序渲染模块
  for (final key in order) {
    switch (key) {
      case ModuleKeys.verbal:         _renderVerbal(rows, plan, font, rh); break;
      case ModuleKeys.reasoning:      _renderReasoning(rows, plan, font, rh); break;
      case ModuleKeys.quantity:       _renderQuantity(rows, plan, font, rh); break;
      case ModuleKeys.dataAnalysis:   _renderDataAnalysis(rows, plan, font, rh); break;
      case ModuleKeys.politics:       _renderPolitics(rows, plan, font, rh); break;
      case ModuleKeys.currentAffairs: _renderCurrentAffairs(rows, plan, font, rh); break;
      case ModuleKeys.shenlun:        _renderShenlun(rows, plan, font, rh); break;
    }
  }

  return pw.Table(border: null, columnWidths: _colWidths, children: rows);
}
```

- [ ] **Step 5: Verify full project analyzes cleanly**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf && flutter analyze
```
Expected: No issues found.

- [ ] **Step 6: Run tests**

```bash
cd /Users/chengfan/project/out_schedule_to_pdf && flutter test
```
Expected: All tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/services/pdf_generator.dart
git commit -m "feat: refactor pdf generator for module order support"
```

---

## Scope Verification (against design spec)

| Spec Requirement | Implemented In |
|---|---|
| ModuleKeys constants + default order | Task 1 (module_keys.dart) |
| PersistenceService get/save module order | Task 1 (persistence_service.dart) |
| ReorderScreen with ReorderableListView | Task 2 (reorder_screen.dart) |
| Settings button on input screen | Task 3 (input_screen.dart) |
| Load saved order on app start | Task 3 (_loadModuleOrder) |
| PDF generator accepts order param | Task 4 (generatePdf moduleOrder) |
| Render modules in specified order | Task 4 (_buildTable switch) |
| Summary always last (unchanged) | Not in order list, always after table |

All spec requirements covered. No extra features implemented.
