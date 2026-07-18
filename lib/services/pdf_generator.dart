import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/study_plan.dart';

class PdfGenerator {
  static const _fontSize = 12.0;
  static const _headerFontSize = 14.0;
  static const _infoFontSize = 14.0;

  /// 7列宽度 (0=大列, 1=子项目, 2=空栏, 3=完成, 4=做题时间, 5=复盘时间, 6=总用时)
  static const _colWidths = {
    0: pw.FlexColumnWidth(0.8),
    1: pw.FlexColumnWidth(1.8),
    2: pw.FlexColumnWidth(3.0),
    3: pw.FlexColumnWidth(1.0),
    4: pw.FlexColumnWidth(1.8),
    5: pw.FlexColumnWidth(1.8),
    6: pw.FlexColumnWidth(1.5),
  };

  /// 垂直堆叠文字（如 "判断推理" → "判\n断\n推\n理"）
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
        pw.SizedBox(height: 0),
        _buildSummary(font),
      ],
    ));
    return pdf.save();
  }

  static pw.Widget _buildHeader(StudyPlan plan, pw.Font font) {
    final examText = plan.daysUntilExam == 0
        ? '今天考试'
        : '距考试还有 ${plan.daysUntilExam} 天';
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      pw.Center(
          child: pw.Text('模块学习',
              style: pw.TextStyle(
                  font: font,
                  fontSize: _headerFontSize,
                  fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 6),
      pw.Center(
          child: pw.Text(
              '${plan.planDate.year}年 ${plan.planDate.month}月 ${plan.planDate.day}日 ${plan.weekdayChinese}'
              '    学习时长：________ $examText',
              style: pw.TextStyle(
                  font: font,
                  fontSize: _infoFontSize,
                  fontWeight: pw.FontWeight.bold))),
    ]);
  }

  /// 单元格（7列）
  static pw.Widget _cell(String text, pw.Font font, {double height = 28}) {
    // 如果文字包含换行，使用多行文本并居中
    final hasNewline = text.contains('\n');
    final child = hasNewline
        ? pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: text
                .split('\n')
                .map((line) => pw.Text(line,
                    style: pw.TextStyle(
                        font: font,
                        fontSize: _fontSize,
                        fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center))
                .toList())
        : (text.isEmpty
            ? pw.SizedBox.shrink()
            : pw.Text(text,
                style: pw.TextStyle(
                    font: font,
                    fontSize: _fontSize,
                    fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center));

    return pw.Container(
      width: double.infinity,
      height: height,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3),
      child: child,
    );
  }

  // ─── 表格 ────────────────────────────────────────────────────

  static pw.Widget _buildTable(StudyPlan plan, pw.Font font) {
    final rows = <pw.TableRow>[];
    const rh = 30.0;

    // Header
    rows.add(pw.TableRow(children: [
      _cell('任务', font, height: rh),
      _cell('', font, height: rh),
      _cell('', font, height: rh),
      _cell('完成', font, height: rh),
      _cell('做题时间', font, height: rh),
      _cell('复盘时间', font, height: rh),
      _cell('总用时', font, height: rh),
    ]));

    // ── 言语 ──
    final vItems = plan.verbalItemList;
    if (vItems.isEmpty) {
      rows.add(_r7(['言语', '', '', '', '', '', ''], font));
    } else {
      for (int i = 0; i < vItems.length; i++) {
        rows.add(_r7(
            [i == 0 ? _vstack('言语') : '', vItems[i], '', '', '', '', ''],
            font));
      }
    }

    // ── 判断推理 ──
    final rItems = plan.reasoningItemList;
    if (rItems.isEmpty) {
      rows.add(_r7(['判断推理', '', '', '', '', '', ''], font));
    } else {
      for (int i = 0; i < rItems.length; i++) {
        rows.add(_r7([
          i == 0 ? _vstack('判断推理') : '',
          rItems[i],
          '',
          '',
          '',
          '',
          ''
        ], font));
      }
    }

    // ── 数量 ──
    rows.add(_r7([_vstack('数量'), '', '', '', '', '', ''], font));
    rows.add(_r7(['', '', '', '', '', '', ''], font));

    // ── 资料分析 ──
    rows.add(_r7([_vstack('资料分析'), '', '', '', '', '', ''], font));
    rows.add(_r7(['', '', '', '', '', '', ''], font));

    // ── 政治理论 ──
    rows.add(_r7([_vstack('政治理论'), '', '', '', '', '', ''], font));

    // ── 常识 ──
    rows.add(_r7(['常识', '', '', '', '', '', ''], font));

    // ── 申论 ──
    rows.add(_r7(['申论', '小题', '', '', '', '', ''], font));
    rows.add(_r7(['', '', '概括题', '', '', '', ''], font));
    rows.add(_r7(['', '', '分析题', '', '', '', ''], font));
    rows.add(_r7(['', '', '贯彻执行', '', '', '', ''], font));
    rows.add(_r7(['', '大作文', '', '', '', '', ''], font));

    return pw.Table(
      border: const pw.TableBorder(
        top: pw.BorderSide(color: PdfColors.black, width: 0.5),
        bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
        left: pw.BorderSide(color: PdfColors.black, width: 0.5),
        right: pw.BorderSide(color: PdfColors.black, width: 0.5),
        horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
        verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
      ),
      columnWidths: _colWidths,
      children: rows,
    );
  }

  /// 总结及心得（全宽，无内部线）
  static pw.Widget _buildSummary(pw.Font font) {
    return pw.Container(
      width: double.infinity,
      height: 170,
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
      child: pw.Text('总结及心得：',
          style: pw.TextStyle(
              font: font,
              fontSize: _fontSize,
              fontWeight: pw.FontWeight.bold)),
    );
  }

  /// 7列辅助
  static pw.TableRow _r7(List<String> texts, pw.Font font) {
    assert(texts.length == 7);
    return pw.TableRow(children: [
      _cell(texts[0], font),
      _cell(texts[1], font),
      _cell(texts[2], font),
      _cell(texts[3], font),
      _cell(texts[4], font),
      _cell(texts[5], font),
      _cell(texts[6], font),
    ]);
  }
}
