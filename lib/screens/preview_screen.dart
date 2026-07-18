import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;

  const PreviewScreen({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF预览'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '保存',
            onPressed: () => _savePdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '分享',
            onPressed: () => _sharePdf(context),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _pdfData(),
        initialPageFormat: PdfPageFormat.a4,
        canChangePageFormat: false,
      ),
    );
  }

  Future<Uint8List> _pdfData() async => pdfBytes;

  Future<void> _savePdf(BuildContext context) async {
    await Printing.layoutPdf(
      onLayout: (format) => _pdfData(),
      name: 'module_study_plan.pdf',
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'module_study_plan.pdf',
    );
  }
}
