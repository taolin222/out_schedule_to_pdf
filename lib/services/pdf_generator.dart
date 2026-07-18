import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/study_plan.dart';

class PdfGenerator {
  static const _fontSize = 9.0;
  static const _headerFontSize = 16.0;
  static const _infoFontSize = 10.0;

  static Future<Uint8List> generatePdf(StudyPlan plan) async {
    final pdf = pw.Document();

    // Load font
    final fontData =
        await rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf');
    final fontBoldData =
        await rootBundle.load('assets/fonts/NotoSansSC-Bold.ttf');
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
              font: fontBold,
              fontSize: _headerFontSize,
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

  static pw.Widget _buildTable(StudyPlan plan, pw.Font font) {
    final verbalItems = plan.verbalItemList;
    final reasoningItems = plan.reasoningItemList;

    // Build table rows
    final rows = <pw.TableRow>[];

    // Header row
    rows.add(_headerRow(font));

    // 言语 section (dynamic rows based on verbalItems)
    if (verbalItems.isEmpty) {
      rows.add(_categoryRow('言语', font));
    } else {
      rows.addAll(_dynamicSectionRows('言语', verbalItems, font));
    }

    // 判断推理 section (dynamic rows based on reasoningItems)
    if (reasoningItems.isEmpty) {
      rows.add(_categoryRow('判断推理', font));
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

  /// Creates a simple category row (for single-row sections).
  static pw.TableRow _categoryRow(
    String category,
    pw.Font font,
  ) {
    return pw.TableRow(
      children: [
        _cell(category, font),
        _emptyCell(font),
        _emptyCell(font),
        _emptyCell(font),
        _emptyCell(font),
      ],
    );
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
            _cell(category, font)
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
    // 资料分析 is split into 资料/分析 across 2 rows
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
          alignment: pw.Alignment.center,
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
