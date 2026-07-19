import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/study_plan.dart';

/// PDF 生成器
/// 根据 StudyPlan 数据，生成一张 A4 学习计划表
class PdfGenerator {
  // ─── 字体大小常量 ────────────────────────────────────────────
  static const _fontSize = 12.0;       // 表格内文字
  static const _headerFontSize = 14.0;  // 标题 "模块学习"
  static const _infoFontSize = 14.0;    // 日期、考试倒计时信息行

  // ─── 7 列宽度比例 ────────────────────────────────────────────
  //  0 = 大列（分类名）  1 = 子项目  2 = 空栏
  //  3 = 完成  4 = 做题时间  5 = 复盘时间  6 = 总用时
  //  第0列与第2列等宽，使第1列（"任务"所在列）正好居中
  static const _colWidths = {
    0: pw.FlexColumnWidth(1.9),
    1: pw.FlexColumnWidth(1.8),
    2: pw.FlexColumnWidth(1.9),
    3: pw.FlexColumnWidth(1.0),
    4: pw.FlexColumnWidth(1.8),
    5: pw.FlexColumnWidth(1.8),
    6: pw.FlexColumnWidth(1.5),
  };

  /// 将分类名称的文字垂直堆叠排列
  /// 例如 "判断推理" → "判\n断\n推\n理"（每字一行）
  static String _vstack(String text) {
    if (text == '判断推理') return '判\n断\n推\n理';
    if (text == '言语') return '言\n语';
    if (text == '数量') return '数\n量';
    if (text == '资料分析') return '资料\n分析';
    if (text == '政治理论') return '政治\n理论';
    return text;
  }

  // ─── 入口：生成 PDF 文件 ────────────────────────────────────

  static Future<Uint8List> generatePdf(StudyPlan plan) async {
    final pdf = pw.Document();               // 创建空白 PDF
    // 加载中文字体（可变字体，一个文件包含所有字重）
    final fontData =
        await rootBundle.load('assets/fonts/NotoSansSC-Variable.ttf');
    final font = pw.Font.ttf(fontData);

    // 往 PDF 里加一页 A4 页面
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
          marginBottom: 20, marginTop: 20, marginLeft: 25, marginRight: 25),
      build: (context) => [
        _buildHeader(plan, font),   // 标题 + 日期信息行
        pw.SizedBox(height: 8),
        _buildTable(plan, font),    // 学习计划表格
        pw.SizedBox(height: 0),
        _buildSummary(font),        // 总结（与表格同宽）
      ],
    ));
    return pdf.save();  // 返回 PDF 字节数据
  }

  // ─── 标题区 ──────────────────────────────────────────────────

  /// 生成顶部的标题和信息行
  /// 格式：
  ///   模块学习
  ///   2026年 7月 19日 周日    学习时长：________ 距考试还有 87 天
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

  // ─── 单元格生成 ──────────────────────────────────────────────

  /// 生成一个单元格，可控制边框
  /// [bottomBorder] = true   → 底部有横线（分隔不同模块）
  /// [noVertical]   = true   → 无左右竖线（用于总结行）
  static pw.Widget _borderedCell(String text, pw.Font font,
      {double height = 30,
      bool bottomBorder = true,
      bool noVertical = false}) {
    // 如果文字包含 \n（如 "判\n断\n推\n理"），用 Column 垂直排列
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
            ? pw.SizedBox.shrink()                    // 空单元格不显示内容
            : pw.Text(text,
                style: pw.TextStyle(font: font, fontSize: _fontSize, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center));     // 普通文字居中

    return pw.Container(
      width: double.infinity,
      height: height,
      // 边框控制：底部线 + 左右竖线
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: bottomBorder
              ? const pw.BorderSide(color: PdfColors.black, width: 0.5)
              : pw.BorderSide.none,  // 同一模块内的行之间不画线
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

  /// 创建一行（固定 7 列）
  static pw.TableRow _makeRow(List<String> texts, pw.Font font,
      {double height = 30, bool bottomBorder = true}) {
    assert(texts.length == 7);  // 必须是 7 列
    // 首列  +  中间 5 列  +  尾列
    final left = _borderedCell(texts[0], font, height: height, bottomBorder: bottomBorder);
    final middle = List.generate(5, (i) =>
        _borderedCell(texts[i + 1], font, height: height, bottomBorder: bottomBorder));
    final right = _borderedCell(texts[6], font, height: height, bottomBorder: bottomBorder);
    return pw.TableRow(children: [left, ...middle, right]);
  }

  // ─── 表格主体构建 ────────────────────────────────────────────

  /// 生成完整的 7 列学习计划表格
  static pw.Widget _buildTable(StudyPlan plan, pw.Font font) {
    final rows = <pw.TableRow>[];
    const rh = 30.0;  // 每行高度

    // ── 表头行 ─────────────────────────────────────────────────
    // "任务" 横跨前 3 列（大列+子项目+空栏），去掉中间的竖线
    rows.add(pw.TableRow(children: [
      pw.Container(width: double.infinity, height: rh,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
            left: pw.BorderSide(color: PdfColors.black, width: 0.5),
          ),
        ),
        child: pw.SizedBox.shrink()),
      // "任务" 在第1列居中，视觉上横跨前3列的中间位置
      pw.Container(width: double.infinity, height: rh,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
          ),
        ),
        alignment: pw.Alignment.center,
        child: pw.Text('任务', style: pw.TextStyle(font: font, fontSize: _fontSize, fontWeight: pw.FontWeight.bold))),
      pw.Container(width: double.infinity, height: rh,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
            right: pw.BorderSide(color: PdfColors.black, width: 0.5),
          ),
        ),
        child: pw.SizedBox.shrink()),
      // 第3-6列：正常左右线
      _borderedCell('完成', font, height: rh),
      _borderedCell('做题时间', font, height: rh),
      _borderedCell('复盘时间', font, height: rh),
      _borderedCell('总用时', font, height: rh),
    ]));

    // ── 言语 ───────────────────────────────────────────────────
    // 从用户输入拆分行，每行一个子项目（逻辑填空/语句衔接/片段阅读）
    final vItems = plan.verbalItemList;
    for (int i = 0; i < vItems.length; i++) {
      rows.add(_makeRow(
          [i == 0 ? _vstack('言语') : '', vItems[i], '', '', '', '', ''], font,
          height: rh,
          bottomBorder: i == vItems.length - 1));  // 最后一行才画底部线
    }

    // ── 判断推理 ───────────────────────────────────────────────
    final rItems = plan.reasoningItemList;
    for (int i = 0; i < rItems.length; i++) {
      rows.add(_makeRow(
          [i == 0 ? _vstack('判断推理') : '', rItems[i], '', '', '', '', ''], font,
          height: rh,
          bottomBorder: i == rItems.length - 1));
    }

    // ── 数量（固定 2 行，无子项目） ─────────────────────────────
    rows.add(_makeRow([_vstack('数量'), '', '', '', '', '', ''], font,
        height: rh, bottomBorder: false));
    rows.add(_makeRow(['', '', '', '', '', '', ''], font,
        height: rh, bottomBorder: true));

    // ── 资料分析（固定 2 行） ───────────────────────────────────
    rows.add(_makeRow([_vstack('资料分析'), '', '', '', '', '', ''], font,
        height: rh, bottomBorder: false));
    rows.add(_makeRow(['', '', '', '', '', '', ''], font,
        height: rh, bottomBorder: true));

    // ── 政治理论（固定 1 行） ───────────────────────────────────
    rows.add(_makeRow([_vstack('政治理论'), '', '', '', '', '', ''], font,
        height: rh, bottomBorder: true));

    // ── 常识（固定 1 行） ───────────────────────────────────────
    rows.add(_makeRow(['常识', '', '', '', '', '', ''], font,
        height: rh, bottomBorder: true));

    // ── 申论 ───────────────────────────────────────────────────
    // 小题（3 个子项：概括题/分析题/贯彻执行）+ 大作文
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

    // ── 总结及心得 ── 在表格外部用 _buildSummary() 渲染 ──────

    // 表格外框（内部线由每个 cell 自己控制）
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

  /// 总结及心得（独立于表格外，全宽显示，无内部线条）
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
          style: pw.TextStyle(font: font, fontSize: _fontSize, fontWeight: pw.FontWeight.bold)),
    );
  }
}
