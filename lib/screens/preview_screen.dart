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
        title: const Text('预览'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: '保存',
            onPressed: () => _savePdf(),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: '分享',
            onPressed: () => _sharePdf(),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfBytes,
        initialPageFormat: PdfPageFormat.a4,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }

  Future<void> _savePdf() async {
    await Printing.layoutPdf(
      onLayout: (format) => pdfBytes,
      name: 'module_study_plan.pdf',
    );
  }

  Future<void> _sharePdf() async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'module_study_plan.pdf',
    );
  }
}
