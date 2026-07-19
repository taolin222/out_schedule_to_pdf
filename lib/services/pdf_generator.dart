import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/study_plan.dart';

/// PDF 生成器
class PdfGenerator {
  static const _fontSize = 12.0;
  static const _headerFontSize = 14.0;
  static const _infoFontSize = 14.0;

  // 8列：0=大列 1=中项目(合并区) 2=子项目 3=空栏 4=完成 5=做题 6=复盘 7=总用时
  static const _colWidths = {
    0: pw.FlexColumnWidth(0.95),
    1: pw.FlexColumnWidth(1.35), // 子项目 文字+1字
    2: pw.FlexColumnWidth(1.35), // 子子项目(申论)
    3: pw.FlexColumnWidth(3.5), // 空栏 吸收剩余
    4: pw.FlexColumnWidth(1.0),
    5: pw.FlexColumnWidth(1.8),
    6: pw.FlexColumnWidth(1.8),
    7: pw.FlexColumnWidth(1.5),
  };

  static String _catChar(String category, int row) {
    const chars = {
      '判断推理': ['判', '断', '推', '理'],
      '言语': ['言', '语'],
      '数量': ['数', '量'],
      '资料分析': ['资料', '分析'],
      '政治理论': ['政治理论'],
    };
    final list = chars[category];
    if (list != null && row < list.length) return list[row];
    return row == 0 ? category : '';
  }

  static Future<Uint8List> generatePdf(StudyPlan plan) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load(
      'assets/fonts/NotoSansSC-Medium.ttf',
    );
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
          pw.SizedBox(height: 0),
          _buildSummary(font),
        ],
      ),
    );
    return pdf.save();
  }

  static pw.Widget _buildHeader(StudyPlan plan, pw.Font font) {
    final examText = '距考试还有 ${plan.daysUntilExam} 天';
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
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              '${plan.planDate.year}年 ${plan.planDate.month}月 ${plan.planDate.day}日 ${plan.weekdayChinese}    学习时长：',
              style: pw.TextStyle(
                font: font,
                fontSize: _infoFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Container(
              width: 80,
              height: _infoFontSize + 2,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                ),
              ),
            ),
            pw.SizedBox(width: 4),
            pw.Text(
              '  $examText',
              style: pw.TextStyle(
                font: font,
                fontSize: _infoFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _borderedCell(
    String text,
    pw.Font font, {
    double height = 38,
    bool bottomBorder = true,
    bool alignLeft = false,
    bool noRightBorder = false,
    bool noLeftBorder = false,
    bool topBorder = false,
  }) {
    final child = text.isEmpty
        ? pw.SizedBox.shrink()
        : pw.Text(
            text,
            style: pw.TextStyle(
              font: font,
              fontSize: _fontSize,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.left,
          );
    return pw.Container(
      width: double.infinity,
      height: height,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: topBorder
              ? const pw.BorderSide(color: PdfColors.black, width: 0.5)
              : pw.BorderSide.none,
          bottom: bottomBorder
              ? const pw.BorderSide(color: PdfColors.black, width: 0.5)
              : pw.BorderSide.none,
          left: noLeftBorder
              ? pw.BorderSide.none
              : const pw.BorderSide(color: PdfColors.black, width: 0.5),
          right: noRightBorder
              ? pw.BorderSide.none
              : const pw.BorderSide(color: PdfColors.black, width: 0.5),
        ),
      ),
      alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
      padding: pw.EdgeInsets.only(left: alignLeft ? 6 : 2, right: 2),
      child: child,
    );
  }

  static pw.TableRow _makeRow(
    List<String> texts,
    pw.Font font, {
    double height = 38,
    bool bottomBorder = true,
    bool mergeCol0 = false,
    bool mergeCol1 = false,
    bool mergeCol1Right = false,
    bool mergeCol2Right = false,
    int leftAlignCol = -1,
  }) {
    assert(texts.length == 8);
    final cells = List.generate(8, (i) {
      bool noBottom = (i == 0 && mergeCol0) || (i == 1 && mergeCol1);
      bool noRight = (i == 1 && mergeCol1Right) || (i == 2 && mergeCol2Right);
      bool noLeft = (i == 2 && mergeCol1Right) || (i == 3 && mergeCol2Right);
      return _borderedCell(
        texts[i],
        font,
        height: height,
        bottomBorder: bottomBorder && !noBottom,
        alignLeft: i == leftAlignCol,
        noRightBorder: noRight,
        noLeftBorder: noLeft,
      );
    });
    return pw.TableRow(children: cells);
  }

  // ─── 表格 ────────────────────────────────────────────────────

  static pw.Widget _buildTable(StudyPlan plan, pw.Font font) {
    final rows = <pw.TableRow>[];
    const rh = 32.0;

    // 表头
    rows.add(
      pw.TableRow(
        children: [
          _borderedCell(
            '',
            font,
            height: rh,
            topBorder: true,
            noRightBorder: true,
          ),
          _borderedCell(
            '',
            font,
            height: rh,
            topBorder: true,
            noRightBorder: true,
            noLeftBorder: true,
          ),
          _borderedCell(
            '任务',
            font,
            height: rh,
            topBorder: true,
            noRightBorder: true,
            noLeftBorder: true,
          ),
          _borderedCell(
            '',
            font,
            height: rh,
            topBorder: true,
            noLeftBorder: true,
          ),
          _borderedCell('完成', font, height: rh, topBorder: true),
          _borderedCell('做题时间', font, height: rh, topBorder: true),
          _borderedCell('复盘时间', font, height: rh, topBorder: true),
          _borderedCell('总用时', font, height: rh, topBorder: true),
        ],
      ),
    );

    // 言语（动态）
    final vItems = plan.verbalItemList;
    for (int i = 0; i < vItems.length; i++) {
      rows.add(
        _makeRow(
          [_catChar('言语', i), vItems[i], '', '', '', '', '', ''],
          font,
          height: rh,
          bottomBorder: true,
          mergeCol0: i < vItems.length - 1,
          mergeCol1Right: true,
          leftAlignCol: 1,
        ),
      );
    }

    // 判断推理（动态）
    final rItems = plan.reasoningItemList;
    for (int i = 0; i < rItems.length; i++) {
      rows.add(
        _makeRow(
          [_catChar('判断推理', i), rItems[i], '', '', '', '', '', ''],
          font,
          height: rh,
          bottomBorder: true,
          mergeCol0: i < rItems.length - 1,
          mergeCol1Right: true,
          leftAlignCol: 1,
        ),
      );
    }

    // 数量（固定2行）
    rows.add(
      _makeRow(
        [_catChar('数量', 0), '', '', '', '', '', '', ''],
        font,
        height: 26,
        bottomBorder: true,
        mergeCol0: true,
        mergeCol1Right: true, mergeCol2Right: true,
      ),
    );
    rows.add(
      _makeRow(
        [_catChar('数量', 1), '', '', '', '', '', '', ''],
        font,
        height: 26,
        bottomBorder: true,
        mergeCol1Right: true, mergeCol2Right: true,
      ),
    );

    // 资料分析（固定2行）
    rows.add(
      _makeRow(
        [_catChar('资料分析', 0), '', '', '', '', '', '', ''],
        font,
        height: 26,
        bottomBorder: true,
        mergeCol0: true,
        mergeCol1Right: true, mergeCol2Right: true,
      ),
    );
    rows.add(
      _makeRow(
        [_catChar('资料分析', 1), '', '', '', '', '', '', ''],
        font,
        height: 26,
        bottomBorder: true,
        mergeCol1Right: true, mergeCol2Right: true,
      ),
    );

    // 政治理论
    rows.add(
      pw.TableRow(
        children: [
          pw.Container(
            width: double.infinity,
            height: rh + 6,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
                left: pw.BorderSide(color: PdfColors.black, width: 0.5),
                right: pw.BorderSide(color: PdfColors.black, width: 0.5),
              ),
            ),
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.symmetric(horizontal: 6),
            child: pw.Text(
              '政治理论',
              style: pw.TextStyle(
                font: font,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Container(
            width: double.infinity,
            height: rh + 6,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
              ),
            ),
            child: pw.SizedBox.shrink(),
          ),
          pw.Container(
            width: double.infinity,
            height: rh + 6,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
              ),
            ),
            child: pw.SizedBox.shrink(),
          ),
          pw.Container(
            width: double.infinity,
            height: rh + 6,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
              ),
            ),
            child: pw.SizedBox.shrink(),
          ),
          _borderedCell('', font, height: rh + 6),
          _borderedCell('', font, height: rh + 6),
          _borderedCell('', font, height: rh + 6),
          _borderedCell('', font, height: rh + 6),
        ],
      ),
    );

    // 常识
    rows.add(
      _makeRow(
        ['常识', '', '', '', '', '', '', ''],
        font,
        height: rh,
        bottomBorder: true,
        mergeCol1Right: true,
        mergeCol2Right: true,
      ),
    );

    // 申论（小题+概括题/分析题/贯彻执行+大作文）
    rows.add(
      _makeRow(
        ['', '小题', '概括题', '', '', '', '', ''],
        font,
        height: rh,
        bottomBorder: true,
        mergeCol0: true,
        mergeCol1: true,
        leftAlignCol: 2,
      ),
    );
    rows.add(
      _makeRow(
        ['申论', '', '分析题', '', '', '', '', ''],
        font,
        height: rh,
        bottomBorder: true,
        mergeCol0: true,
        mergeCol1: true,
        leftAlignCol: 2,
      ),
    );
    rows.add(
      _makeRow(
        ['', '', '贯彻执行', '', '', '', '', ''],
        font,
        height: rh,
        bottomBorder: true,
        mergeCol0: true,
        leftAlignCol: 2,
      ),
    );
    rows.add(
      _makeRow(
        ['', '大作文', '', '', '', '', '', ''],
        font,
        height: rh,
        bottomBorder: true,
        mergeCol2Right: true,
        leftAlignCol: 1,
      ),
    );

    return pw.Table(border: null, columnWidths: _colWidths, children: rows);
  }

  // ─── 总结 ────────────────────────────────────────────────────

  static pw.Widget _buildSummary(pw.Font font) {
    return pw.Container(
      width: double.infinity,
      height: 150,
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.black, width: 0.5),
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
          left: pw.BorderSide(color: PdfColors.black, width: 0.5),
          right: pw.BorderSide(color: PdfColors.black, width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.topLeft,
      child: pw.Text(
        '总结及心得：',
        style: pw.TextStyle(
          font: font,
          fontSize: _fontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }
}
