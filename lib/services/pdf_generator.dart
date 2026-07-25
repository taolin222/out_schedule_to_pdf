import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/module_keys.dart';
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

  // 2字一行（例：判断推理→"判断"/"推理"），根据子项目数自动调字体大小
  static String _cat2Line(String name, int itemCount, int row) {
    if (name.length >= 4) {
      if (row == 0) return name.substring(0, 2);
      if (row == 1) return name.substring(2, 4);
    }
    return row == 0 ? name : '';
  }

  // 仅分类名（其余列全空）
  static List<String> _c8(String cat) => [cat, '', '', '', '', '', '', ''];
  // 分类名+子项目
  static List<String> _ci8(String cat, String item) => [
    cat,
    item,
    '',
    '',
    '',
    '',
    '',
    '',
  ];

  // 旧版单字拆分（用于数量/资料分析等）
  static String _catChar(String category, int row) {
    const chars = {
      '言语': ['言', '语'],
      '数量': ['数', '量'],
      '资料分析': ['资料', '分析'],
      '政治常识': ['政治常识'],
    };
    final list = chars[category];
    if (list != null && row < list.length) return list[row];
    return row == 0 ? category : '';
  }

  static Future<Uint8List> generatePdf(StudyPlan plan, {List<String>? moduleOrder}) async {
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
          _buildTable(plan, font, moduleOrder: moduleOrder),
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
    double fontSize = _fontSize,
  }) {
    final child = text.isEmpty
        ? pw.SizedBox.shrink()
        : pw.Text(
            text,
            style: pw.TextStyle(
              font: font,
              fontSize: fontSize,
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
              ? const pw.BorderSide(color: PdfColors.black, width: 0.8)
              : pw.BorderSide.none,
          bottom: bottomBorder
              ? const pw.BorderSide(color: PdfColors.black, width: 0.8)
              : pw.BorderSide.none,
          left: noLeftBorder
              ? pw.BorderSide.none
              : const pw.BorderSide(color: PdfColors.black, width: 0.8),
          right: noRightBorder
              ? pw.BorderSide.none
              : const pw.BorderSide(color: PdfColors.black, width: 0.8),
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
    bool mergeCol1Right = true,
    bool mergeCol2Right = true,
    int leftAlignCol = -1,
    double catFontSize = _fontSize,
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
        fontSize: i == 0 ? catFontSize : _fontSize,
      );
    });
    return pw.TableRow(children: cells);
  }

  // ─── 模块渲染函数（可排序） ──────────────────────────────────

  static void _renderVerbal(List<pw.TableRow> rows, StudyPlan plan, pw.Font font, double rh) {
    final vItems = plan.verbalItemList;
    for (int i = 0; i < vItems.length; i++) {
      final catTxt = vItems.length > 1 ? _catChar('言语', i) : (i == 0 ? '言语' : '');
      rows.add(_makeRow(_ci8(catTxt, vItems[i]), font,
          height: rh, mergeCol1Right: false, mergeCol0: i < vItems.length - 1, leftAlignCol: 1));
    }
  }

  static void _renderReasoning(List<pw.TableRow> rows, StudyPlan plan, pw.Font font, double rh) {
    final rItems = plan.reasoningItemList;
    for (int i = 0; i < rItems.length; i++) {
      rows.add(_makeRow(_ci8(_cat2Line('判断推理', rItems.length, i), rItems[i]), font,
          height: rh, mergeCol1Right: false, mergeCol0: i < rItems.length - 1, leftAlignCol: 1));
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
    // 使用统一的 _makeRow，确保边框与其他模块一致
    rows.add(_makeRow(['政治\n常识', '', '', '', '', '', '', ''], font, height: rh + 6, catFontSize: 11));
  }

  static void _renderCurrentAffairs(List<pw.TableRow> rows, StudyPlan plan, pw.Font font, double rh) {
    rows.add(_makeRow(_c8('时政'), font, height: rh));
  }

  static void _renderShenlun(List<pw.TableRow> rows, StudyPlan plan, pw.Font font, double rh) {
    rows.add(_makeRow(['', '小题', '概括题', '', '', '', '', ''], font,
        height: rh, mergeCol1Right: false, mergeCol2Right: false, mergeCol0: true, mergeCol1: true, leftAlignCol: 2));
    rows.add(_makeRow(['申论', '', '分析题', '', '', '', '', ''], font,
        height: rh, mergeCol1Right: false, mergeCol2Right: false, mergeCol0: true, mergeCol1: true, leftAlignCol: 2));
    rows.add(_makeRow(['', '', '贯彻执行', '', '', '', '', ''], font,
        height: rh, mergeCol1Right: false, mergeCol2Right: false, mergeCol0: true, leftAlignCol: 2));
    rows.add(_makeRow(['', '大作文', '', '', '', '', '', ''], font,
        height: rh, mergeCol1Right: false, mergeCol2Right: false, leftAlignCol: 1));
  }

  // ─── 表格 ────────────────────────────────────────────────────

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

  // ─── 总结 ────────────────────────────────────────────────────

  static pw.Widget _buildSummary(pw.Font font) {
    return pw.Container(
      width: double.infinity,
      height: 180,
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
