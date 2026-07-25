# 模块排序功能 — 设计文档

**日期：** 2026-07-25
**项目：** out_schedule_to_pdf
**关联设计：** 2026-07-18-study-plan-pdf-generator-design.md

---

## 1. 概述

用户可自定义 PDF 中学习计划模块的显示顺序（总结及心得固定最后）。设置保存在本地，下次启动自动生效。无配置时使用默认顺序。

---

## 2. 可排序模块

| 标识符 | 默认位置 | 说明 |
|---|---|---|
| 言语理解 | 1 | 动态行 |
| 判断推理 | 2 | 动态行 |
| 数量 | 3 | 固定2行 |
| 资料分析 | 4 | 固定2行 |
| 政治常识 | 5 | 固定1行 |
| 时政 | 6 | 固定1行 |
| 申论 | 7 | 固定小题+大作文 |

**总结及心得** — 不可移动，始终在表格最下方。

---

## 3. 页面设计

### 3.1 入口

首页右上角添加齿轮图标 ⚙️，点击进入排序页面。

### 3.2 排序页面（reorder_screen.dart）

```
 ┌─────────────────────────────┐
 │  ← 返回    模块排序          │
 ├─────────────────────────────┤
 │                             │
 │  ≡ 言语理解                  │
 │  ≡ 判断推理                  │
 │  ≡ 数量                     │
 │  ≡ 资料分析                  │
 │  ≡ 政治常识                  │
 │  ≡ 时政                     │
 │  ≡ 申论                     │
 │                             │
 │  ┌─────────────────────┐    │
 │  │     保存               │    │
 │  └─────────────────────┘    │
 └─────────────────────────────┘
```

- 使用 `ReorderableListView` 拖拽排序
- 每行左侧显示拖拽把手 ≡
- 点击保存后存到 `SharedPreferences`

---

## 4. 数据存储

**存储介质：** `SharedPreferences`

| Key | Value 示例 | 说明 |
|---|---|---|
| `module_order` | `"言语理解,判断推理,数量,资料分析,政治常识,时政,申论"` | 模块顺序，逗号分隔 |

**无存储值时：** 使用上述默认顺序。

---

## 5. 数据模型

```dart
/// 模块标识符常量
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
}
```

---

## 6. 涉及修改的文件

| 文件 | 改动 |
|---|---|
| `lib/screens/input_screen.dart` | 右上角添加设置按钮 |
| `lib/screens/reorder_screen.dart` | **新建** — 拖拽排序页面 |
| `lib/services/persistence_service.dart` | 添加 `getModuleOrder()` / `saveModuleOrder()` |
| `lib/services/pdf_generator.dart` | `_buildTable` 按传入顺序渲染模块 |

---

## 7. 持久化服务扩展

```dart
class PersistenceService {
  static const _orderKey = 'module_order';

  static Future<String?> getModuleOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_orderKey);
  }

  static Future<void> saveModuleOrder(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orderKey, value);
  }

  // 已有方法保留...
}
```

---

## 8. PDF Generator 改动

`_buildTable(StudyPlan plan, pw.Font font)` 增加可选参数 `List<String>? moduleOrder`。

```dart
static pw.Widget _buildTable(StudyPlan plan, pw.Font font, {List<String>? moduleOrder}) {
  final order = moduleOrder ?? ModuleKeys.defaultOrder;
  
  for (final key in order) {
    switch (key) {
      case ModuleKeys.verbal:  _renderVerbal(rows, plan, font, rh);  break;
      case ModuleKeys.reasoning: _renderReasoning(rows, plan, font, rh); break;
      // ... 每个模块独立渲染函数
    }
  }
}
```

每个模块的渲染逻辑从内联代码抽出独立函数，便于按需调用。

---

## 9. 不作实现

- 列名自定义（取消）
- 模块隐藏
- 多组配置切换
- 云端同步
- 导出/导入配置

---

*此设计由 brainstorming 流程产生，下一步将转入 writing-plans 创建实施计划。*
