import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';                // for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:pdf/pdf.dart';                           // for PdfPageFormat
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '/models/document/page_data.dart';                         // single PageData model

class PreviewScreen extends StatefulWidget {
  final List<PageData> pages;
  const PreviewScreen({Key? key, required this.pages}) : super(key: key);

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    for (var i = 0; i < widget.pages.length; i++) {
      final p = widget.pages[i];
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) {
            final content = <pw.Widget>[];
            content.add(pw.Header(level: 0, text: 'Page ${i + 1}'));
            content.add(pw.Paragraph(text: p.controller.document.toPlainText()));
            if (p.inlineImages.isNotEmpty) {
              content.add(pw.Header(level: 1, text: 'Inline Images'));
              for (var img in p.inlineImages) {
                final bytes = img.readAsBytesSync();
                content.add(pw.Image(pw.MemoryImage(bytes), width: 100, height: 100));
              }
            }
            if (p.blankPageImages.isNotEmpty) {
              content.add(pw.Header(level: 1, text: 'Page Images'));
              content.add(pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: p.blankPageImages.map((img) {
                  final bytes = img.readAsBytesSync();
                  return pw.Image(pw.MemoryImage(bytes), width: 80, height: 80);
                }).toList(),
              ));
            }
            if (p.signature != null) {
              content.add(pw.Header(level: 1, text: 'Signature'));
              content.add(pw.Image(pw.MemoryImage(p.signature!)));
            }
            if (p.name != null) content.add(pw.Paragraph(text: 'Name: ${p.name}'));
            if (p.credentials != null) content.add(pw.Paragraph(text: 'Credentials: ${p.credentials}'));
            return content;
          },
        ),
      );
    }
    return pdf.save();
  }

  void _exportPdf() async {
    final bytes = await _generatePdf();
    await Printing.sharePdf(bytes: bytes, filename: 'report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview (${_currentPage + 1}/${widget.pages.length})'),
        actions: [IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportPdf)],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.pages.length,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (ctx, i) {
          final p = widget.pages[i];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Page ${i + 1}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // Read-only Quill editor with config
                quill.QuillEditor.basic(controller: p.controller, 
                  config: quill.QuillEditorConfig(
                    
                    //readOnly: true,
                    scrollable: true,
                    placeholder: '',
                    autoFocus: false,
                    showCursor: false,
                    expands: false,
                    padding: EdgeInsets.zero,
                    embedBuilders: kIsWeb
                        ? FlutterQuillEmbeds.editorWebBuilders()
                        : FlutterQuillEmbeds.editorBuilders(),
                  ),
                ),
                const SizedBox(height: 12),
                if (p.inlineImages.isNotEmpty) ...[
                  const Text('Inline Images', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.inlineImages.map((img) => Image.file(img, width: 80, height: 80)).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (p.blankPageImages.isNotEmpty) ...[
                  const Text('Page Images', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.blankPageImages.map((img) => Image.file(img, width: 80, height: 80)).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (p.signature != null) ...[
                  const Text('Signature', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Image.memory(p.signature!, width: 200, height: 100),
                  const SizedBox(height: 12),
                ],
                if (p.name != null) Text('Name: ${p.name}'),
                if (p.credentials != null) Text('Credentials: ${p.credentials}'),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _currentPage > 0
                    ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _currentPage < widget.pages.length - 1
                    ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
