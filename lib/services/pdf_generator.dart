import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/study_plan.dart';

class PdfGenerator {
  static const _fontSize = 12.0;
  static const _headerFontSize = 14.0;
  static const _infoFontSize = 14.0;

  static const _colWidths = {
    0: pw.FlexColumnWidth(0.8),
    1: pw.FlexColumnWidth(1.8),
    2: pw.FlexColumnWidth(3.0),
    3: pw.FlexColumnWidth(1.0),
    4: pw.FlexColumnWidth(1.8),
    5: pw.FlexColumnWidth(1.8),
    6: pw.FlexColumnWidth(1.5),
  };

  static String _vstack(String text) {
    if (text == '判断推理') return '判\n断\n推\n理';
    if (text == '言语') return '言\n语';
    if (text == '数量') return '数\n量';
    if (text == '资料分析') return '资料\n分析';
    if (text == '政治理论') return '政治\n理论';
    return text;
  }

  static Future<Uint8List> generatePdf(StudyPlan plan) async {
    final pdf = pw.Document();
    final fontData =
        await rootBundle.load('assets/fonts/NotoSansSC-Variable.ttf');
    final font = pw.Font.ttf(fontData);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
          marginBottom: 20, marginTop: 20, marginLeft: 25, marginRight: 25),
      build: (context) => [
        _buildHeader(plan, font),
        pw.SizedBox(height: 8),
        _buildTable(plan, font),
      ],
    ));
    return pdf.save();
  }

  static pw.Widget _buildHeader(StudyPlan plan, pw.Font font) {
    final examText = '距考试还有 ${plan.daysUntilExam} 天';
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      pw.Center(child: pw.Text('模块学习',
          style: pw.TextStyle(font: font, fontSize: _headerFontSize, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 6),
      pw.Center(child: pw.Text(
          '${plan.planDate.year}年 ${plan.planDate.month}月 ${plan.planDate.day}日 ${plan.weekdayChinese}'
          '    学习时长：________ $examText',
          style: pw.TextStyle(font: font, fontSize: _infoFontSize, fontWeight: pw.FontWeight.bold))),
    ]);
  }

  /// 创建单元格，带边框控制
  /// [bottomBorder] 是否有底部边框
  /// [noVertical] 是否无左右边框（用于总结行）
  static pw.Widget _borderedCell(String text, pw.Font font,
      {double height = 30,
      bool bottomBorder = true,
      bool noVertical = false}) {
    final hasNewline = text.contains('\n');
    final child = hasNewline
        ? pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: text
                .split('\n')
                .map((l) => pw.Text(l,
                    style: pw.TextStyle(font: font, fontSize: _fontSize, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center))
                .toList())
        : (text.isEmpty
            ? pw.SizedBox.shrink()
            : pw.Text(text,
                style: pw.TextStyle(font: font, fontSize: _fontSize, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center));

    return pw.Container(
      width: double.infinity,
      height: height,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: bottomBorder
              ? const pw.BorderSide(color: PdfColors.black, width: 0.5)
              : pw.BorderSide.none,
          left: noVertical
              ? pw.BorderSide.none
              : const pw.BorderSide(color: PdfColors.black, width: 0.5),
          right: noVertical
              ? pw.BorderSide.none
              : const pw.BorderSide(color: PdfColors.black, width: 0.5),
        ),
      ),
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3),
      child: child,
    );
  }

  /// 创建一行（7列）
  static pw.TableRow _makeRow(List<String> texts, pw.Font font,
      {double height = 30, bool bottomBorder = true}) {
    assert(texts.length == 7);
    final left = _borderedCell(texts[0], font, height: height, bottomBorder: bottomBorder);
    final middle = List.generate(5, (i) =>
        _borderedCell(texts[i + 1], font, height: height, bottomBorder: bottomBorder));
    final right = _borderedCell(texts[6], font, height: height, bottomBorder: bottomBorder);
    return pw.TableRow(children: [left, ...middle, right]);
  }

  /// 总结行（7列合并为一块，无内部竖线）
  static pw.TableRow _summaryRow(pw.Font font) {
    final cell = pw.Container(
      width: double.infinity,
      height: 170,
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
          left: pw.BorderSide(color: PdfColors.black, width: 0.5),
          right: pw.BorderSide(color: PdfColors.black, width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.topLeft,
      child: pw.Text('总结及心得：',
          style: pw.TextStyle(font: font, fontSize: _fontSize, fontWeight: pw.FontWeight.bold)),
    );
    // 返回一行，所有7个children都是同一个cell引用（但只有第一个会被显示）
    return pw.TableRow(children: [
      cell, pw.SizedBox.shrink(), pw.SizedBox.shrink(),
      pw.SizedBox.shrink(), pw.SizedBox.shrink(),
      pw.SizedBox.shrink(), pw.SizedBox.shrink(),
    ]);
  }

  // ─── 表格构建 ────────────────────────────────────────────────

  static pw.Widget _buildTable(StudyPlan plan, pw.Font font) {
    final rows = <pw.TableRow>[];
    const rh = 30.0;

    // Header
    rows.add(_makeRow(['任务', '', '', '完成', '做题时间', '复盘时间', '总用时'], font,
        height: rh, bottomBorder: true));

    // ── 言语 ──
    final vItems = plan.verbalItemList;
    for (int i = 0; i < vItems.length; i++) {
      rows.add(_makeRow(
          [i == 0 ? _vstack('言语') : '', vItems[i], '', '', '', '', ''], font,
          height: rh, bottomBorder: i == vItems.length - 1));
    }

    // ── 判断推理 ──
    final rItems = plan.reasoningItemList;
    for (int i = 0; i < rItems.length; i++) {
      rows.add(_makeRow(
          [i == 0 ? _vstack('判断推理') : '', rItems[i], '', '', '', '', ''], font,
          height: rh, bottomBorder: i == rItems.length - 1));
    }

    // ── 数量 ──
    rows.add(_makeRow([_vstack('数量'), '', '', '', '', '', ''], font,
        height: rh, bottomBorder: false));
    rows.add(_makeRow(['', '', '', '', '', '', ''], font,
        height: rh, bottomBorder: true));

    // ── 资料分析 ──
    rows.add(_makeRow([_vstack('资料分析'), '', '', '', '', '', ''], font,
        height: rh, bottomBorder: false));
    rows.add(_makeRow(['', '', '', '', '', '', ''], font,
        height: rh, bottomBorder: true));

    // ── 政治理论 ──
    rows.add(_makeRow([_vstack('政治理论'), '', '', '', '', '', ''], font,
        height: rh, bottomBorder: true));

    // ── 常识 ──
    rows.add(_makeRow(['常识', '', '', '', '', '', ''], font,
        height: rh, bottomBorder: true));

    // ── 申论 ──
    rows.add(_makeRow(['申论', '小题', '', '', '', '', ''], font,
        height: rh, bottomBorder: false));
    rows.add(_makeRow(['', '', '概括题', '', '', '', ''], font,
        height: rh, bottomBorder: false));
    rows.add(_makeRow(['', '', '分析题', '', '', '', ''], font,
        height: rh, bottomBorder: false));
    rows.add(_makeRow(['', '', '贯彻执行', '', '', '', ''], font,
        height: rh, bottomBorder: false));
    rows.add(_makeRow(['', '大作文', '', '', '', '', ''], font,
        height: rh, bottomBorder: true));

    // ── 总结 ──
    rows.add(_summaryRow(font));

    // 表格：只画外边框，内部线由 cell 自己控制
    return pw.Table(
      border: const pw.TableBorder(
        top: pw.BorderSide(color: PdfColors.black, width: 0.5),
        left: pw.BorderSide(color: PdfColors.black, width: 0.5),
        right: pw.BorderSide(color: PdfColors.black, width: 0.5),
      ),
      columnWidths: _colWidths,
      children: rows,
    );
  }
}
