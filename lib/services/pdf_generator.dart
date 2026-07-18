import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/study_plan.dart';

class PdfGenerator {
  static const _fontSize = 12.0;
  static const _headerFontSize = 14.0;
  static const _infoFontSize = 14.0;

  static Future<Uint8List> generatePdf(StudyPlan plan) async {
    final pdf = pw.Document();
    final fontData =
        await rootBundle.load('assets/fonts/NotoSansSC-Variable.ttf');
    final font = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginBottom: 20, marginTop: 20, marginLeft: 25, marginRight: 25,
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
        pw.Center(child: pw.Text('模块学习',
            style: pw.TextStyle(font: font, fontSize: _headerFontSize, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 6),
        pw.Center(child: pw.Text(
          '${plan.planDate.year}年 ${plan.planDate.month}月 ${plan.planDate.day}日 ${plan.weekdayChinese}'
          '    学习时长：________ $examText',
          style: pw.TextStyle(font: font, fontSize: _infoFontSize, fontWeight: pw.FontWeight.bold),
        )),
      ],
    );
  }

  // ─── 7 列宽度 ─────────────────────────────────────────────────
  // 0=大列  1=子项目  2=空栏  3=完成  4=做题时间  5=复盘时间  6=总用时
  static const _colWidths = {
    0: pw.FlexColumnWidth(0.8),
    1: pw.FlexColumnWidth(1.8),
    2: pw.FlexColumnWidth(3.0),
    3: pw.FlexColumnWidth(1.0),
    4: pw.FlexColumnWidth(1.8),
    5: pw.FlexColumnWidth(1.8),
    6: pw.FlexColumnWidth(1.5),
  };

  /// 创建带边框控制的单元格
  /// [borderTop/borderBottom/borderLeft/borderRight] 控制四边边框
  static pw.Widget _bCell(String text, pw.Font font,
      {bool borderTop = false,
      bool borderBottom = false,
      bool borderLeft = false,
      bool borderRight = false,
      double height = 28}) {
    final sides = <pw.BorderSide>{};
    if (borderTop) sides.add(pw.BorderSide(color: PdfColors.black, width: 0.5));
    if (borderBottom) sides.add(pw.BorderSide(color: PdfColors.black, width: 0.5));
    if (borderLeft) sides.add(pw.BorderSide(color: PdfColors.black, width: 0.5));
    if (borderRight) sides.add(pw.BorderSide(color: PdfColors.black, width: 0.5));

    // Build Border from sides
    pw.Border? border;
    if (sides.isNotEmpty) {
      border = pw.Border(
        top: borderTop ? const pw.BorderSide(color: PdfColors.black, width: 0.5) : pw.BorderSide.none,
        bottom: borderBottom ? const pw.BorderSide(color: PdfColors.black, width: 0.5) : pw.BorderSide.none,
        left: borderLeft ? const pw.BorderSide(color: PdfColors.black, width: 0.5) : pw.BorderSide.none,
        right: borderRight ? const pw.BorderSide(color: PdfColors.black, width: 0.5) : pw.BorderSide.none,
      );
    }

    return pw.Container(
      width: double.infinity,
      height: height,
      decoration: border != null ? pw.BoxDecoration(border: border) : null,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      child: text.isEmpty
          ? pw.SizedBox.shrink()
          : pw.Text(text,
              style: pw.TextStyle(
                  font: font,
                  fontSize: _fontSize,
                  fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center),
    );
  }

  /// 创建一行（7列），统一控制边框
  static List<pw.Widget> _row7({
    required List<String> texts,
    required pw.Font font,
    bool top = false,
    bool bottom = false,
    double height = 28,
  }) {
    assert(texts.length == 7);
    return List.generate(7, (i) {
      final left = i == 0;
      final right = i == 6;
      return _bCell(texts[i], font,
          borderTop: top,
          borderBottom: bottom,
          borderLeft: left,
          borderRight: right,
          height: height);
    });
  }

  /// 创建总结行（7列合并为一个整块）
  static List<pw.Widget> _summaryRow7(pw.Font font,
      {bool top = false, bool bottom = false, double height = 170}) {
    return [
      pw.Container(
        width: double.infinity,
        height: height,
        decoration: pw.BoxDecoration(
          border: pw.Border(
            top: top
                ? const pw.BorderSide(color: PdfColors.black, width: 0.5)
                : pw.BorderSide.none,
            bottom: bottom
                ? const pw.BorderSide(color: PdfColors.black, width: 0.5)
                : pw.BorderSide.none,
            left: const pw.BorderSide(color: PdfColors.black, width: 0.5),
            right: const pw.BorderSide(color: PdfColors.black, width: 0.5),
          ),
        ),
        padding: const pw.EdgeInsets.all(8),
        alignment: pw.Alignment.topLeft,
        child: pw.Text('总结及心得：',
            style: pw.TextStyle(
                font: font,
                fontSize: _fontSize,
                fontWeight: pw.FontWeight.bold)),
      ),
      // 剩余 6 列（无任何线条）
      pw.SizedBox.shrink(),
      pw.SizedBox.shrink(),
      pw.SizedBox.shrink(),
      pw.SizedBox.shrink(),
      pw.SizedBox.shrink(),
      pw.SizedBox.shrink(),
    ];
  }

  // ─── 表格构建 ─────────────────────────────────────────────────

  static pw.Widget _buildTable(StudyPlan plan, pw.Font font) {
    final rows = <pw.TableRow>[];
    double rh = 28; // 行高

    // Header row
    rows.add(pw.TableRow(
      children: _row7(texts: ['任务', '', '', '完成', '做题时间', '复盘时间', '总用时'],
          font: font, top: true, bottom: true, height: rh),
    ));

    // ── 言语（动态） ──
    final vItems = plan.verbalItemList;
    if (vItems.isEmpty) {
      rows.add(pw.TableRow(
          children: _row7(texts: ['言语', '', '', '', '', '', ''], font: font, top: false, bottom: true, height: rh)));
    } else {
      for (int i = 0; i < vItems.length; i++) {
        final cells = ['', '', '', '', '', '', ''];
        if (i == 0) cells[0] = '言语';
        cells[1] = vItems[i];
        rows.add(pw.TableRow(
            children: _row7(texts: cells, font: font,
                top: false,
                bottom: i == vItems.length - 1,
                height: rh)));
      }
    }

    // ── 判断推理（动态） ──
    final rItems = plan.reasoningItemList;
    if (rItems.isEmpty) {
      rows.add(pw.TableRow(
          children: _row7(texts: ['判断推理', '', '', '', '', '', ''], font: font, top: false, bottom: true, height: rh)));
    } else {
      for (int i = 0; i < rItems.length; i++) {
        final cells = ['', '', '', '', '', '', ''];
        if (i == 0) cells[0] = '判断推理';
        cells[1] = rItems[i];
        rows.add(pw.TableRow(
            children: _row7(texts: cells, font: font,
                top: false,
                bottom: i == rItems.length - 1,
                height: rh)));
      }
    }

    // ── 数量（2行，子项目列留空） ──
    rows.add(pw.TableRow(
        children: _row7(texts: ['数量', '', '', '', '', '', ''], font: font, top: false, bottom: false, height: rh)));
    rows.add(pw.TableRow(
        children: _row7(texts: ['', '', '', '', '', '', ''], font: font, top: false, bottom: true, height: rh)));

    // ── 资料分析（2行） ──
    rows.add(pw.TableRow(
        children: _row7(texts: ['资料', '', '', '', '', '', ''], font: font, top: false, bottom: false, height: rh)));
    rows.add(pw.TableRow(
        children: _row7(texts: ['分析', '', '', '', '', '', ''], font: font, top: false, bottom: true, height: rh)));

    // ── 政治理论（1行） ──
    rows.add(pw.TableRow(
        children: _row7(texts: ['政治理论', '', '', '', '', '', ''], font: font, top: false, bottom: true, height: rh)));

    // ── 常识（1行） ──
    rows.add(pw.TableRow(
        children: _row7(texts: ['常识', '', '', '', '', '', ''], font: font, top: false, bottom: true, height: rh)));

    // ── 申论 ──
    // 申论 + 小题
    rows.add(pw.TableRow(
        children: _row7(texts: ['申论', '小题', '', '', '', '', ''], font: font, top: false, bottom: false, height: rh)));
    // 概括题
    rows.add(pw.TableRow(
        children: _row7(texts: ['', '', '概括题', '', '', '', ''], font: font, top: false, bottom: false, height: rh)));
    // 分析题
    rows.add(pw.TableRow(
        children: _row7(texts: ['', '', '分析题', '', '', '', ''], font: font, top: false, bottom: false, height: rh)));
    // 贯彻执行
    rows.add(pw.TableRow(
        children: _row7(texts: ['', '', '贯彻执行', '', '', '', ''], font: font, top: false, bottom: false, height: rh)));
    // 大作文
    rows.add(pw.TableRow(
        children: _row7(texts: ['', '大作文', '', '', '', '', ''], font: font, top: false, bottom: true, height: rh)));

    // ── 总结及心得（整块无分割线） ──
    rows.add(pw.TableRow(
        children: _summaryRow7(font, top: false, bottom: true, height: 170)));

    return pw.Table(
      border: null,
      columnWidths: _colWidths,
      children: rows,
    );
  }
}
