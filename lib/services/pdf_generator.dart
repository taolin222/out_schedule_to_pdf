import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/study_plan.dart';

class PdfGenerator {
  static const _fontSize = 12.0;
  static const _headerFontSize = 14.0;
  static const _infoFontSize = 14.0;

  /// 固定模块定义：名称 → 行数
  /// 资料分析特殊处理（拆为"资料"/"分析"两行）
  static const _fixedSections = {
    '数量': 2,
    '资料分析': -2, // 负号表示拆分为 "资料" "分析"
    '政治理论': 1,
    '常识': 1,
  };

  /// 申论子项目定义：[列, 文本]（列0=第一列 申论, 列1=第二列 子类, 列2=第三列 子项）
  static const _shenlunItems = [
    [0, '申论'],
    [1, '小题'],
    [2, '概括题'],
    [2, '分析题'],
    [2, '贯彻执行'],
    [1, '大作文'],
  ];

  static Future<Uint8List> generatePdf(StudyPlan plan) async {
    final pdf = pw.Document();

    // Load font (variable font supports all weights)
    final fontData =
        await rootBundle.load('assets/fonts/NotoSansSC-Variable.ttf');
    final font = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginBottom: 20,
          marginTop: 20,
          marginLeft: 25,
          marginRight: 25,
        ),
        build: (context) => [
          _buildHeader(plan, font),
          pw.SizedBox(height: 8),
          _buildTable(plan, font),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(StudyPlan plan, pw.Font font) {
    final examText = plan.daysUntilExam == 0
        ? '今天考试'
        : '距考试还有 ${plan.daysUntilExam} 天';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Center(
          child: pw.Text(
            '模块学习',
            style: pw.TextStyle(
              font: font,
              fontSize: _headerFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            '${plan.planDate.year}年 ${plan.planDate.month}月 ${plan.planDate.day}日 ${plan.weekdayChinese}'
            '    学习时长：________ $examText',
            style: pw.TextStyle(font: font, fontSize: _infoFontSize),
          ),
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: _fontSize,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Container _emptyCell(pw.Font font) =>
      pw.Container(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4));

  /// 创建一行 5 列表格
  static pw.TableRow _row5(List<String> texts, pw.Font font,
      {bool allBold = false}) {
    return pw.TableRow(
      children: texts
          .map((t) => t.isNotEmpty
              ? _cell(t, font, isHeader: allBold)
              : _emptyCell(font))
          .toList(),
    );
  }

  static pw.TableRow _headerRow(pw.Font font) =>
      _row5(['任务', '完成', '做题时间', '复盘时间', '总用时'], font, allBold: true);

  /// 动态模块行：分类 + N 个子项
  static List<pw.TableRow> _dynamicSectionRows(
      String category, List<String> items, pw.Font font) {
    return items.asMap().entries.map((e) {
      final cells = <String>['', e.value, '', '', ''];
      if (e.key == 0) cells[0] = category;
      return _row5(cells, font);
    }).toList();
  }

  /// 固定模块行（数据驱动，替代原 _fixedSectionRows + _shenlunRows）
  static List<pw.TableRow> _fixedSectionRows(
      String category, int rowCount, pw.Font font) {
    if (rowCount == -2) {
      // 资料分析：拆为资料/分析两行
      return [
        _row5(['资料', '', '', '', ''], font),
        _row5(['分析', '', '', '', ''], font),
      ];
    }
    return List.generate(rowCount, (i) {
      return _row5([i == 0 ? category : '', '', '', '', ''], font);
    });
  }

  static List<pw.TableRow> _shenlunRows(pw.Font font) {
    return _shenlunItems.map((item) {
      final cells = ['', '', '', '', ''];
      cells[item[0] as int] = item[1] as String;
      return _row5(cells, font);
    }).toList();
  }

  static pw.TableRow _summaryRow(pw.Font font) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          alignment: pw.Alignment.center,
          child: pw.Text('总结及心得：',
              style: pw.TextStyle(font: font, fontSize: _fontSize)),
        ),
        _emptyCell(font),
        _emptyCell(font),
        _emptyCell(font),
        _emptyCell(font),
      ],
    );
  }

  static pw.Widget _buildTable(StudyPlan plan, pw.Font font) {
    final rows = <pw.TableRow>[];

    rows.add(_headerRow(font));

    // 动态模块：言语
    final verbalItems = plan.verbalItemList;
    rows.addAll(verbalItems.isEmpty
        ? _fixedSectionRows('言语', 1, font)
        : _dynamicSectionRows('言语', verbalItems, font));

    // 动态模块：判断推理
    final reasoningItems = plan.reasoningItemList;
    rows.addAll(reasoningItems.isEmpty
        ? _fixedSectionRows('判断推理', 1, font)
        : _dynamicSectionRows('判断推理', reasoningItems, font));

    // 固定模块（数据驱动）
    for (final entry in _fixedSections.entries) {
      rows.addAll(_fixedSectionRows(entry.key, entry.value, font));
    }

    // 申论
    rows.addAll(_shenlunRows(font));

    // 总结
    rows.add(_summaryRow(font));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(5.6),
        1: const pw.FlexColumnWidth(1.0),
        2: const pw.FlexColumnWidth(1.8),
        3: const pw.FlexColumnWidth(1.8),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: rows,
    );
  }
}
